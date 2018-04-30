## Run the application

This application can be run in several forms and shapes, going from running each component locally on your laptop as the first development stage to running them as a production-like application and hosting it in production-ready environments such as IBM Cloud Public or IBM Cloud Private.

In this section, we will describe how to run the Java MicroProfile based BlueCompute application at different development-like/production-like levels.

### Pre-requisites

In order to work with the BlueCompute application, we need first to download the source code for each of its components and build it.

#### Source code

There are two ways to get the code for each of the application's components:

1. Manually executing `git clone <app-component-github-repo-uri>` and checking out the respective `microprofile` branch for each of the BlueCompute application's components (listed [here](#project-component-repositories)).

2. Execute `sh clone_peers.sh` within the `utility_scripts` folder provided in this repository and it will clone all BleCompute components' github repos and checkout their `microprofile` branch for you.

```
user-MacBook-Pro:utility_scripts user@ibm.com$ ./clone_peers.sh 
Cloning from GitHub Organization or User Account of "ibm-cloud-architecture".
--> To override this value, run "export CUSTOM_GITHUB_ORG=your-github-org" prior to running this script.
Cloning from repository branch "microprofile".
--> To override this value, pass in the desired branch as a parameter to this script. E.g "./clone-peers.sh master"
Press ENTER to continue


Cloning refarch-cloudnative-bluecompute-web project
Cloning into '../../refarch-cloudnative-bluecompute-web'...
remote: Counting objects: 2097, done.
remote: Compressing objects: 100% (79/79), done.
remote: Total 2097 (delta 65), reused 91 (delta 42), pack-reused 1972
Receiving objects: 100% (2097/2097), 2.18 MiB | 2.45 MiB/s, done.
Resolving deltas: 100% (1231/1231), done.

Cloning refarch-cloudnative-auth project
Cloning into '../../refarch-cloudnative-auth'...
remote: Counting objects: 856, done.
remote: Compressing objects: 100% (144/144), done.
remote: Total 856 (delta 88), reused 214 (delta 68), pack-reused 607
Receiving objects: 100% (856/856), 476.68 KiB | 363.00 KiB/s, done.
Resolving deltas: 100% (377/377), done.

Cloning refarch-cloudnative-micro-inventory project
Cloning into '../../refarch-cloudnative-micro-inventory'...
remote: Counting objects: 3507, done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3507 (delta 0), reused 0 (delta 0), pack-reused 3504
Receiving objects: 100% (3507/3507), 757.70 KiB | 429.00 KiB/s, done.
Resolving deltas: 100% (1905/1905), done.

Cloning refarch-cloudnative-micro-orders project
Cloning into '../../refarch-cloudnative-micro-orders'...
remote: Counting objects: 1151, done.
remote: Total 1151 (delta 0), reused 0 (delta 0), pack-reused 1151
Receiving objects: 100% (1151/1151), 356.04 KiB | 329.00 KiB/s, done.
Resolving deltas: 100% (549/549), done.

Cloning refarch-cloudnative-micro-customer project
Cloning into '../../refarch-cloudnative-micro-customer'...
remote: Counting objects: 1339, done.
remote: Total 1339 (delta 0), reused 0 (delta 0), pack-reused 1339
Receiving objects: 100% (1339/1339), 28.89 MiB | 3.00 MiB/s, done.
Resolving deltas: 100% (708/708), done.
```

#### Build code

Again, there are two ways of building the code for each of the BlueCompute application's components:

1. Manually executing `cd ../<app-component-name> && mvn install` for each of the BlueCompute's components (listed [here](#project-component-repositories)).

2. We are using Apache Maven for managing the build processes for each of the microservices making up the BlueCompute application as well as the overall/project build process for building the entire application altogether at once. Therefore, in order to build the source code for each of the microservices making up the BlueCompute application you just need to execute:

`mvn clean package`

You should see the following output:

```
[INFO] ------------------------------------------------------------------------
[INFO] Building project 0.1.0-SNAPSHOT
[INFO] ------------------------------------------------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ project ---
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO] 
[INFO] inventory .......................................... SUCCESS [01:01 min]
[INFO] catalog ............................................ SUCCESS [ 57.074 s]
[INFO] Auth ............................................... SUCCESS [01:30 min]
[INFO] customer ........................................... SUCCESS [01:05 min]
[INFO] orders ............................................. SUCCESS [ 55.541 s]
[INFO] project ............................................ SUCCESS [  0.002 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 05:30 min
[INFO] Finished at: 2018-04-30T14:11:33-05:00
[INFO] Final Memory: 38M/463M
[INFO] ------------------------------------------------------------------------
```
