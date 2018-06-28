set -e

#You’ll need to configure Maven to use more memory than usual by setting MAVEN_OPTS
export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"

#Now clean and install Maven, skip tests so that it does not take a long time;
#multiple cores are used for further speeding up the execution of the command
./build/mvn clean install -DskipTests -T10C

#Then build the package
./build/mvn -Pyarn -Phadoop-2.7 -Dhadoop.version=2.7.1 -DskipTests package

#Then make distribution, for that Comment the build command in dev/make-distribution.sh as we have done the build earlier
#"${BUILD_COMMAND[@]}"

./dev/make-distribution.sh --name custom-spark --tgz -Psparkr -Phadoop-2.7 -Phive -Phive-thriftserver -Pyarn
 
#Now copy from dist folder to deb/usr/share/spark
rm -rf deb
cp -r debian deb

PACKAGE=fk-fdp-spark
DEB_VERSION=`date +%Y%m%d%H%M`
DEB_TAG=`git log --format="%H" -n 1`
DEB_FILE_NAME=${PACKAGE}_${DEB_VERSION}_${DEB_TAG}.deb



#replace control file _VERSION_, _TAG_

sed -i "s|_VERSION_|${DEB_VERSION}|" deb/DEBIAN/control
sed -i "s|_TAG_|${DEB_TAG}|" deb/DEBIAN/control

cat deb/DEBIAN/control


mkdir -p deb/usr/share/spark/
cp -R dist/* deb/usr/share/spark/

rm -R deb/usr/share/spark/examples

#Create the package
dpkg-deb --build deb


mv deb.deb ${DEB_FILE_NAME}.deb


#Now add packages to the repository

REPO_SERVICE_HOST="repo-svc-app-0001.nm.flipkart.com"
REPO_SERVICE_PORT="8080"
REPO_NAME=fk-fdp-spark

reposervice --host $REPO_SERVICE_HOST --port $REPO_SERVICE_PORT pubrepo --repo ${REPO_NAME} --appkey ${PACKAGE} --debs ${DEB_FILE_NAME}.deb
