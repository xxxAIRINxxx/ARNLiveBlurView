PROJECT=Demo/ARNLiveBlurViewDemo.xcodeproj
SCHEME=ARNLiveBlurViewDemo

default: clean build

clean:
		xctool \
		-project ${PROJECT} \
		-scheme ${SCHEME} \
		clean

build:
		xctool \
		-project ${PROJECT} \
		-scheme ${SCHEME} \
		build \
		-sdk iphonesimulator

test:
		xctool \
		-project ${PROJECT} \
		-scheme ${SCHEME} \
		test \
		-test-sdk iphonesimulator \
		-parallelize
