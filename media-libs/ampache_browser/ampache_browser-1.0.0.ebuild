# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CMAKE_MIN_VERSION=3.0

inherit cmake-utils

DESCRIPTION="Ampache desktop client library"
HOMEPAGE="http://ampache-browser.org"
SRC_URI="https://github.com/ampache-browser/ampache_browser/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="nls debug"

RDEPEND="dev-qt/qtconcurrent:5
	dev-qt/qtcore:5
	dev-qt/qtwidgets:5"

DEPEND="${RDEPEND}"

src_configure() {
	local mycmakeargs=(
		-DUSE_NLS="$(usex nls)"
	)
	cmake-utils_src_configure
}
