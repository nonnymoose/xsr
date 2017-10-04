# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="X Steps Recorder"
HOMEPAGE="https://github.com/nonnymoose/xsr"
SRC_URI="https://github.com/nonnymoose/xsr/archive/v1.0.0.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~ALLARCHES"
IUSE="cursor"

DEPEND="dev-lang/perl
	media-gfx/scrot
	cursor? ( media-gfx/imagemagock x11-misc/xdotool )"
RDEPEND="${DEPEND}"

src_install() {
	dobin xsr
	dodoc README.md

	insinto /usr/share/xsr
	doins Cursor.png
}


RESTRICT="primaryuri"
