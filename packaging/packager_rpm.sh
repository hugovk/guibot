#!/bin/bash
set -e

readonly distro="${DISTRO:-fedora}"
readonly distro_version="${VERSION:-30}"

# rpm dependencies
# python3
dnf -y install python3 python3-coverage
# python-imaging
dnf -y install python3-pillow
# pip dependencies (for dependencies not available as RPM)
dnf -y install gcc libX11-devel libXtst-devel python3-devel libpng-devel python3-pip redhat-rpm-config
# contour, template, feature, cascade, text matching
dnf -y install python3-numpy python3-opencv
# text matching
dnf -y install tesseract tesseract-devel
dnf -y install gcc-c++
pip3 install pytesseract==0.3.4 tesserocr==2.5.1
# deep learning
pip3 install torch==1.4.0 torchvision==0.5.0
# screen controlling
pip3 install autopy==4.0.0
pip3 install vncdotool==0.12.0
dnf -y install xdotool xwd ImageMagick
dnf -y install x11vnc

# rpm packaging and installing of current guibot source
dnf -y install rpm-build
ROOT=""
NAME=$(sed -n 's/^Name:[ \t]*//p' "$ROOT/guibot/packaging/guibot.spec")
VERSION=$(sed -n 's/^Version:[ \t]*//p' "$ROOT/guibot/packaging/guibot.spec")
cp -r "$ROOT/guibot" "$ROOT/$NAME-$VERSION"
mkdir -p ~/rpmbuild/SOURCES
tar czvf ~/rpmbuild/SOURCES/$NAME-$VERSION.tar.gz -C "$ROOT/" --exclude=.* --exclude=*.pyc $NAME-$VERSION
rpmbuild -ba "$ROOT/$NAME-$VERSION/packaging/guibot.spec" --with opencv
cp ~/rpmbuild/RPMS/x86_64/python3-$NAME-$VERSION*.rpm "$ROOT/guibot"
dnf -y install "$ROOT/guibot/python3-"$NAME-$VERSION*.rpm
rm -fr "$ROOT/$NAME-$VERSION"

# virtual display
dnf install -y xorg-x11-server-Xvfb
export DISPLAY=:99.0
Xvfb :99 -screen 0 1024x768x24 &> /tmp/xvfb.log  &
sleep 3  # give xvfb some time to start

# unit tests
dnf install -y python3-PyQt5
cd /lib/python3*/site-packages/guibot/tests
if (( distro_version <= 30 )); then
    COVERAGE="python3-coverage"
else
    COVERAGE="coverage"
fi
LIBPATH=".." COVERAGE="$COVERAGE" sh run_tests.sh

exit 0
