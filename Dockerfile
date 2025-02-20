FROM ubuntu:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    gpg \
    wget \
    lsb-release \
    nano \
    curl \
    unzip \
    groff \
    jq

# Verify Terraform source
RUN wget -O - https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) \
         signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
         https://apt.releases.hashicorp.com $(lsb_release -cs) main" \ 
         | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
RUN apt-get update && apt-get install -y terraform

WORKDIR /home/ubuntu

# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN git clone https://github.com/bartosz-bear/IaC-intro.git

WORKDIR /home/ubuntu/IaC-intro/local

RUN terraform init && \
    terraform validate

WORKDIR /home/ubuntu/IaC-intro/creds

COPY creds/creds.json /home/ubuntu/IaC-intro/creds/creds.json

RUN aws configure set aws_access_key_id "$(jq -r '.aws.ACCESS_KEY' /home/ubuntu/IaC-intro/creds/creds.json)" && \
    aws configure set aws_secret_access_key "$(jq -r '.aws.SECRET_ACCESS_KEY' /home/ubuntu/IaC-intro/creds/creds.json)" && \
    aws configure set region "$(jq -r '.aws.region' /home/ubuntu/IaC-intro/creds/creds.json)" && \
    aws configure set output json

COPY local/variables.tfvars /home/ubuntu/IaC-intro/local/variables.tfvars

WORKDIR /home/ubuntu/IaC-intro/local

#RUN terraform plan --var-file=variables.tfvars

#RUN terraform import aws_key_pair.sample_key sample-key --help --var-file=variables.tfvars

CMD ["/bin/bash"]