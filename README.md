# iOS MOBBL
![MOBBL](http://itudemobiledev.files.wordpress.com/2014/02/mobbl-logo.png?w=362&h=203 "MOBBL logo")

A development framework for data centric mobile iOS apps.

## Overview

Most current app development is about connecting consumers and employees to back-end systems through their tablet or smartphone. MOBBL aims to make these type of apps easier to develop, port and maintain.

## Documentation

Generic documentation can be found at [Mobbl.org](http://mobbl.org/doc.html).
Documentation about how to get started can be [here](http://mobbl.org/ios.html).
For Api documentation, see the [iOS API Reference](http://mobbl.org/apis/ios/index.html).

## [Changelog](https://github.com/ItudeMobile/itude-mobile-ios-mobbl-framework/wiki/Changelog)
Current version: 0.0.2.7

## Build
#### Maven

First add the [ItudeMobile repository](https://github.com/ItudeMobile/maven-repository) to your pom.xml

```xml
<repository>
	<id>itudemobile-github-repository</id>
	<name>ItudeMobile Github repository</name>
	<url>http://mobbl.org/maven-repository/releases</url>
</repository>
```

Now add iOS Mobbl Framework

```xml
<dependency>
    <groupId>com.itude.mobile.ios.mobbl</groupId>
    <artifactId>mobbl-core-framework</artifactId>
    <version>${core.framework.version}</version>
    <type>xcode-framework</type>
</dependency>
```
to your pom.xml.

## Contribute

If you find a bug or have a new feature you want to add, just create a pull request and submit it to us. You can also [file an issue](https://github.com/ItudeMobile/itude-mobile-ios-mobbl-framework/issues/new).

Please note, if you have a pull request, make sure to use the [develop branch](https://github.com/ItudeMobile/itude-mobile-ios-mobbl-framework/tree/develop) as your base.

## License
The code in this project is licensed under the Apache Software License 2.0, per the terms of the included LICENSE file.
