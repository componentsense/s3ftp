# S3FTP

S3FTP is an FTP server that allows you to upload files to S3.

It is based on Alpine, and it uses [s3fs-fuse](https://github.com/s3fs-fuse/s3fs-fuse) and [vsftpd](https://pkgs.alpinelinux.org/packages?name=vsftpd&branch=edge)


# How to use

For each user that you have you need to set up a single environment variable.
```dotenv
ACCESS_KEY_ID="[your aws access key]"
SECRET_ACCESS_KEY="[your aws secret]"
S3FTP_USER_ROOT="root ||| ftp_password ||| s3-bucket-name"
S3FTP_USER_SUSAN="susan ||| ftp_password ||| s3-bucket-name/susan"
S3FTP_USER_JOHN="john ||| ftp_password ||| s3-bucket-name/john"
```
