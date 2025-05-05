# Infrastructure as Code - OpenAI with APIM

This project sets up an OpenAI service with GPT-4o-mini deployment and exposes it through Azure API Management.

## Deployment

## To deploy the infrastructure using a GitHub Actions workflow

You must first configure the repo to be able to connect to Azure. For this, read, edit and execute the init.ps1 file.

It just needs to be done the first time.

## To deploy the infrastructure manually

1) Complete the names in the init.ps1 file and run it

1) Ensure you have a target resource group already created

2) Create a main.bicepparam file with the required params

3) Run the following command:

```bash
az deployment group create \
    --resource-group your-rg \
    --template-file ./deploy/main.bicep \
    --parameters ./deploy/main.bicepparam
```

NOTE: we can add --mode Complete -> deletes any resources in the resource group that aren't defined in the template

4) You can start using the model. Example:

```
POST https://agustin-gabrielli-apim-36ielriklvqjq.azure-api.net/openaitest/deployments/gpt-4o-mini-deployment/chat/completions?api-version=2024-12-01-preview
```

Make sure you set the following headers:
* "api-key" with the APIM subscription key (without "Bearer")
  * you can use the key for the hole APIM instance (not recommended in prod)
  * or you can use the key for each specific API (since here we create a specific subscription for each API)
* Content-Type to application/json

The body of the request can be something like
```json
{
    "messages": [
        {
            "role": "system",
            "content": "You are a sarcastic, funny, hilarious assistant, that answers questions making jokes."
        },
        {
            "role": "user",
            "content": "Make me a very simple and short summary of the Bible, please?"
        }
    ]
}
```

