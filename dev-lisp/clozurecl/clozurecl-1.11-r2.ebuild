# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils flag-o-matic multilib toolchain-funcs

MY_PN=ccl
MY_P=${MY_PN}-${PV}

DESCRIPTION="Common Lisp implementation, derived from Digitool's MCL product"
HOMEPAGE="https://ccl.clozure.com"
SRC_URI="
	x86?   ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-linuxx86.tar.gz )
	amd64? ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-linuxx86.tar.gz )
	arm? ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-linuxarm.tar.gz )
	x86-macos? ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-darwinx86.tar.gz )
	x64-macos? ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-darwinx86.tar.gz )
	x86-solaris? ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-solarisx86.tar.gz )
	x64-solaris? ( ${HOMEPAGE}/ftp/pub/release/${PV}/${MY_P}-solarisx86.tar.gz )
	doc? ( ${HOMEPAGE}/docs/ccl.html )"

LICENSE="LLGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux ~x64-macos"
IUSE="doc"

RDEPEND=">=dev-lisp/asdf-2.33-r3:="
DEPEND="${RDEPEND}"

S="${WORKDIR}"/${MY_PN}
ENVD="${T}/50ccl"

src_configure() {
	if use x86-macos; then
		CCL_RUNTIME=dx86cl; CCL_HEADERS=darwin-x86-headers; CCL_KERNEL=darwinx8632
	elif use x64-macos; then
		CCL_RUNTIME=dx86cl64; CCL_HEADERS=darwin-x86-headers64; CCL_KERNEL=darwinx8664
	elif use x86-solaris; then
		CCL_RUNTIME=sx86cl; CCL_HEADERS=solarisx86-headers; CCL_KERNEL=solarisx86
	elif use x64-solaris; then
		CCL_RUNTIME=sx86cl64; CCL_HEADERS=solarisx64-headers; CCL_KERNEL=solarisx64
	elif use x86; then
		CCL_RUNTIME=lx86cl; CCL_HEADERS=x86-headers; CCL_KERNEL=linuxx8632
	elif use amd64; then
		CCL_RUNTIME=lx86cl64; CCL_HEADERS=x86-headers64; CCL_KERNEL=linuxx8664
	elif use arm; then
		CCL_RUNTIME=armcl; CCL_HEADERS=arm-headers; CCL_KERNEL=linuxarm
	elif use ppc; then
		CCL_RUNTIME=ppccl; CCL_HEADERS=headers; CCL_KERNEL=linuxppc
	elif use ppc64; then
		CCL_RUNTIME=ppccl64; CCL_HEADERS=headers64; CCL_KERNEL=linuxppc64
	fi
}

src_prepare() {
	default
	eapply "${FILESDIR}/${MY_PN}-format.patch"
	# https://lists.clozure.com/pipermail/openmcl-devel/2016-September/011399.html
	sed -i "s/-dynamic/-no_pie/" "${S}/lisp-kernel/darwinx8664/Makefile" || die
	cp "${EPREFIX}/usr/share/common-lisp/source/asdf/build/asdf.lisp" tools/ || die
}

src_compile() {
	emake -C lisp-kernel/${CCL_KERNEL} clean
	emake -C lisp-kernel/${CCL_KERNEL} all CC="$(tc-getCC)"

	unset CCL_DEFAULT_DIRECTORY
	./${CCL_RUNTIME} -n -b -Q -e '(ccl:rebuild-ccl :full t)' -e '(ccl:quit)' || die "Compilation failed"

	# remove non-owner write permissions on the full-image
	chmod go-w ${CCL_RUNTIME}{,.image} || die

	esvn_clean
}

src_install() {
	local target_dir="/usr/$(get_libdir)/${PN}"
	local prefix_dir="${EPREFIX}/${target_dir#/}"

	mkdir -p "${D}/${prefix_dir#/}"

	find . -type f -name '*fsl' -delete || die
	rm -f lisp-kernel/${CCL_KERNEL}/*.o || die
	cp -a compiler contrib level-0 level-1 lib library lisp-kernel scripts \
		tools xdump ${CCL_HEADERS} ${CCL_RUNTIME} ${CCL_RUNTIME}.image \
		"${D}/${prefix_dir#/}" || die

	echo "CCL_DEFAULT_DIRECTORY=${prefix_dir}" > "${ENVD}"
	doenvd "${ENVD}"

	dosym "${target_dir}/${CCL_RUNTIME}" /usr/bin/ccl
	dodoc doc/release-notes.txt

	if use doc ; then
		dodoc "${DISTDIR}/ccl.html"
		dodoc -r doc/manual
		dodoc -r examples
	fi
}
