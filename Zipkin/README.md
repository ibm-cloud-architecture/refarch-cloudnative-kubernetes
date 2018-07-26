## Zipkin

In our sample application, we used **Zipkin** as our distributed tracing system. 

In a microservice based architecture, distributed tracing is a must have component. Distributed tracing system help us to debug several problems like latency issues etc by identifying and analyzing the requests. It helps to us to monitor our applications. It analyzes the transactions and records them. It helps us to understand the overall transaction flow. 

**Helm chart**

We used `openzipkin/zipkin` as our base image and built a basic helm chart on top of it.

You can find the Zipkin Quick start guide [here](https://zipkin.io/pages/quickstart).

**Setting up Zipkin locally**

To set up Zipkin locally, we are running it as a docker container. You need [Docker](https://www.docker.com/) as a prerequisite.

To run Zipkin on docker locally, run the below commands.

`docker run -d -p 9411:9411 openzipkin/zipkin`

You can find the detailed instructions [here](https://zipkin.io/pages/quickstart).

Set the required environment variables as follows.

```
export zipkinHost=localhost
export zipkinPort=9411
```
