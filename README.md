# bucket-antivirus-function

This function is inspired by https://github.com/bluesentry/bucket-antivirus-function.

That repository is long out of date, but we've kept it going. There are many forks of it, but they have varying levels of quality and maintanability.

Scan new objects added to any s3 bucket using AWS Lambda.

## Overall Structure

Read the [README for bluesentry](https://github.com/bluesentry/bucket-antivirus-function/blob/master/README.md) on the overall structure.

The below explains some things that might be relevant for debugging/troubleshooting.

### Dependencies

`clamav` is installed in a docker image, along with its dependencies. The `Dockerfile` puts all the dynamically linked dependencies in the `/tmp/usr/lib64/` folder before copying them to the `/opt/app/bin` folder.

The `/opt/app/bin` folder is what is eventually deployed.

If `clamav` is failing, it might have logs in Cloudwatch like:

> error while loading shared libraries: libjson-c.so.5: cannot open shared object file: No such file or directory

This basically means the dynamically linked library can't be found. This probably means you

#### Debugging code for testing dependencies

I found it helpful to run:

```
docker run -it amazonlinux:2023 /bin/sh
```

Then:

```
yum install cpio yum-utils -y
```

Then:
```
cd /tmp
yumdownloader -x \*i686 --archlist=x86_64 json-c
rpm2cpio json-c*.rpm | cpio -idmv
```

Then look in `/tmp/usr/lib64/` to see what is in there. If your file, e.g. `libjson-c.so` is in there then it'll be included. If it isn't, you need to figure out the right incantations to add it.

Once you run `DOCKER_BUILDKIT=0 make all` (I find it easier to do debugging if BUILDKIT is off) a zip file will be produced.

You can also check in that to see if any of the files you expect to see (e.g. `libjson-c.so`) are missing/present.

Finally, you can upload the `deploy/lambda.zip` into Lambda's console to get it running.