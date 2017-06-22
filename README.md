# Laravel Docker Image

Image based on https://hub.docker.com/r/celerative/nginx-php-fpm

This image contains the latest version of laravel.

Pull the image:

`docker pull celerative/laravel:7.1`

`7.1` tag, specifies the php version not laravel.

Repository: https://github.com/celerative/laravel

## How to use

In order to use this image, you just create your own Dockefile and set this image as the base image, like this:

```Dockerfile
FROM celerative/laravel:7.1

...
```
