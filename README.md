# Terraform Module for a Three-Tier Application on GCP

This Terraform module deploys a three-tier application on Google Cloud Platform (GCP). It creates a Global VPC, an Auto Scaling Group, and a CloudSQL instance.

## Features

- **Virtual Machine**: This module creates virtual machine to build the resources from any region.
- **Global VPC**: This module configures subnets automatically and is capable of creating a new project.
- **Auto Scaling Group**: This module creates an Auto Scaling Group on top of the VPC from the previous step. The Auto Scaling Group uses a minimum of 1 instance and creates its own Load Balancer.
- **CloudSQL**: This module creates a CloudSQL instance to use with the WordPress Auto Scaling Group.
