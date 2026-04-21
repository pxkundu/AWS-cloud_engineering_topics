#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { EcommerceStack } from '../lib/ecommerce-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region:  process.env.CDK_DEFAULT_REGION ?? 'us-east-1',
};

new EcommerceStack(app, 'EcommerceStackDev', {
  env,
  environment:    'dev',
  imageTag:       process.env.IMAGE_TAG ?? 'latest',
  certificateArn: process.env.CERTIFICATE_ARN ?? '',
});

new EcommerceStack(app, 'EcommerceStackProd', {
  env,
  environment:    'prod',
  imageTag:       process.env.IMAGE_TAG ?? 'latest',
  certificateArn: process.env.CERTIFICATE_ARN ?? '',
});
