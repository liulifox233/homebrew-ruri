class QemuAT7 < Formula
    desc "Generic machine emulator and virtualizer"
    homepage "https://www.qemu.org/"
    url "https://download.qemu.org/qemu-7.0.0.tar.xz"
    sha256 "f6b375c7951f728402798b0baabb2d86478ca53d44cedbefabbe1c46bf46f839"
    license "GPL-2.0-only"
    head "https://gitlab.com/qemu-project/qemu.git", branch: "master"
  
    # livecheck do
    #   url "https://www.qemu.org/download/"
    #   regex(/href=.*?qemu[._-]v?(\d+(?:\.\d+)+)\.t/i)
    # end
  
    # bottle do
    #   sha256 arm64_sequoia: "78aa087b52bd2fa9b4d4b8717ba65f0c0c90ac1122a0374f95926dafa15874df"
    #   sha256 arm64_sonoma:  "223081d0571d90360c0fc20e5d837068cd9e99f94fe86d855a68cb06a56cd2fd"
    #   sha256 arm64_ventura: "f22d31f546595d1e1ee306c881d0fb27eb84116b9e0196bcf8cbe317766f5810"
    #   sha256 sonoma:        "46d8e626c52abcc26caa3a160230953556fa2ac52200c2103eac89e022358527"
    #   sha256 ventura:       "1052ccd2a7c1a384160c97f79e31f2f4dcc8c294eb46b75baa3426aa63e76b0f"
    #   sha256 arm64_linux:   "4e485ac01d486873c74628537ee58be0862630afa16f2274e414d9e329a76eb6"
    #   sha256 x86_64_linux:  "0ca672b3f490a70227d5ccf90749ed8a36365aa5f0e8201f8c91fdffc5ac37f9"
    # end
  
    depends_on "libtool" => :build
    depends_on "meson" => :build
    depends_on "ninja" => :build
    depends_on "pkgconf" => :build
    depends_on "python@3.13" => :build # keep aligned with meson
    depends_on "spice-protocol" => :build
  
    depends_on "capstone"
    depends_on "dtc"
    depends_on "glib"
    depends_on "gnutls"
    depends_on "jpeg-turbo"
    depends_on "libpng"
    depends_on "libslirp"
    depends_on "libssh"
    depends_on "libusb"
    depends_on "lzo"
    depends_on "ncurses"
    depends_on "nettle"
    depends_on "pixman"
    depends_on "snappy"
    depends_on "vde"
    depends_on "zstd"
  
    uses_from_macos "bison" => :build
    uses_from_macos "flex" => :build
    uses_from_macos "bzip2"
    uses_from_macos "zlib"
  
    on_linux do
      depends_on "attr"
      depends_on "cairo"
      depends_on "elfutils"
      depends_on "gdk-pixbuf"
      depends_on "gtk+3"
      depends_on "libcap-ng"
      depends_on "libepoxy"
      depends_on "libx11"
      depends_on "libxkbcommon"
      depends_on "mesa"
      depends_on "systemd"
    end
  
    # 820KB floppy disk image file of FreeDOS 1.2, used to test QEMU
    # NOTE: Keep outside test block so that `brew fetch` is able to handle slow download/retries
    resource "homebrew-test-image" do
      url "https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.2/official/FD12FLOPPY.zip"
      sha256 "81237c7b42dc0ffc8b32a2f5734e3480a3f9a470c50c14a9c4576a2561a35807"
    end
  
    def install
      ENV["LIBTOOL"] = "glibtool"
  
      # Remove wheels unless explicitly permitted. Currently this:
      # * removes `meson` so that brew `meson` is always used
      # * keeps `pycotap` which is a pure-python "none-any" wheel (allowed in homebrew/core)
      rm(Dir["python/wheels/*"] - Dir["python/wheels/pycotap-*-none-any.whl"])
  
      args = %W[
        --prefix=#{prefix}
        --cc=#{ENV.cc}
        --host-cc=#{ENV.cc}
        --disable-bsd-user
        --disable-guest-agent
        --enable-slirp
        --enable-capstone
        --enable-curses
        --enable-fdt=system
        --enable-libssh
        --enable-vde
        --enable-virtfs
        --enable-zstd
        --extra-cflags=-DNCURSES_WIDECHAR=1
        --disable-sdl
      ]
  
      # Sharing Samba directories in QEMU requires the samba.org smbd which is
      # incompatible with the macOS-provided version. This will lead to
      # silent runtime failures, so we set it to a Homebrew path in order to
      # obtain sensible runtime errors. This will also be compatible with
      # Samba installations from external taps.
      args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"
  
      args += if OS.mac?
        ["--disable-gtk", "--enable-cocoa"]
      else
        ["--enable-gtk"]
      end
  
      system "./configure", *args
      system "make", "V=1", "install"
    end
  
    test do
      archs = %w[
        aarch64 alpha arm avr hppa i386 loongarch64 m68k microblaze microblazeel mips
        mips64 mips64el mipsel or1k ppc ppc64 riscv32 riscv64 rx
        s390x sh4 sh4eb sparc sparc64 tricore x86_64 xtensa xtensaeb
      ]
      archs.each do |guest_arch|
        assert_match version.to_s, shell_output("#{bin}/qemu-system-#{guest_arch} --version")
      end
  
      resource("homebrew-test-image").stage testpath
      assert_match "file format: raw", shell_output("#{bin}/qemu-img info FLOPPY.img")
  
      # On macOS, verify that we haven't clobbered the signature on the qemu-system-x86_64 binary
      if OS.mac?
        output = shell_output("codesign --verify --verbose #{bin}/qemu-system-x86_64 2>&1")
        assert_match "valid on disk", output
        assert_match "satisfies its Designated Requirement", output
      end
    end
  end