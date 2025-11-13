# Slack Alerts Channel and App Setup Guide

## Step 1: Create a Slack Channel

1. Open **Slack**.  
2. Click **+** next to “Channels” → **Create a channel**.  
3. Give it a name, e.g., `#alerts`.  
4. Set it **public** or **private** and click **Create**.

---

## Step 2: Create a Slack App

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps).  
2. Click **Create New App** → **From scratch**.  
3. Give it a name (e.g., `AlertmanagerBot`) and select your workspace.  
4. Click **Create App**.

---

## Step 3: Enable Incoming Webhooks

1. In your app page, go to **Features → Incoming Webhooks**.  
2. Toggle **Activate Incoming Webhooks** to **ON**.

---

## Step 4: Create a Webhook URL

1. Click **Add New Webhook to Workspace**.  
2. Slack will ask which channel the app can post to → select the channel you created (`#alerts`).  
3. Click **Allow**.  
4. Slack will generate a **Webhook URL** (looks like `https://hooks.slack.com/services/...`).  

> **Important:** Copy this URL — this is what Alertmanager will use to send alerts.
