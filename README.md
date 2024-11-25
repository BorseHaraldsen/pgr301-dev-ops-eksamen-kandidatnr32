# PGR301 EKSAMEN 2024 Couch Explorers - Bærekraftig turisme fra sofakroken ! 

# Kandidatnummer 32 besvarelse.
---
## Oppgave 1: AWS Lambda og GitHub Actions

### A. AWS Lambda-funksjon med SAM og API Gateway
- **Beskrivelse**: Lambda-funksjonen er implementert ved bruk av AWS SAM for å generere bilder via AWS Bedrock. Funksjonen eksponeres gjennom et POST-endepunkt via API Gateway.
- **HTTP Endepunkt lenke til postman testing**: 
- `https://dok2ppwzob.execute-api.eu-west-1.amazonaws.com/Prod/generate-image`

- **Viktig**:
  - S3-bucket-navnet og kandidatnummer hentes dynamisk fra miljøvariabler.
  - Relevant kode ligger i mappen `sam_lambda_32`.
  - Bilder lagres i `s3://pgr301-couch-explorers/32/generated_images`.

### B. GitHub Actions Workflow for SAM-deploy
- **Beskrivelse**: Automatisert workflow som deployer SAM-applikasjonen hver gang det pushes til `main`-branchen.
- **Lenke til kjørt Github Actions Workflow**: [GitHub Actions Workflow](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992557403)

- **Viktig**:
  - Relevant kode ligger i .github/workflows/deploy_lambda_32.yml

---

## Oppgave 2: Infrastruktur med Terraform og SQS

### A. Infrastruktur som kode
- **Beskrivelse**: Terraform er brukt til å opprette en SQS-kø og integrere denne med Lambda for asynkron behandling. Implementasjonen inkluderer:
  - Opprettelse av SQS-kø.
  - IAM-roller for Lambda-SQS-integrasjon og bedrock.
  - Konfigurasjon av Terraform med S3-backend for state-filen.

- **SQS-Kø URL**: `https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32`

- **Viktig**:
  - Bruker fortsatt variabler for ting som kandidatnr, bucket name osv.
  - Relevant kode ligger i mappen infra. (med bruk av lambda_sqs.py)
  - AWS provider versjonen er satt til OVER 1.9.0 og ikke inkluderende, slik som sagt i oppgaven.
  - Bilder lagres i `s3://pgr301-couch-explorers/32/task2_generated_images`.
  - Eksempel test: aws sqs send-message --queue-url https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32 --message-body "Beautiful house on top of an ocean wave"

### B. GitHub Actions Workflow for Terraform
- **Beskrivelse**: Workflow for å deploye infrastrukturen med Terraform, med forskjellig oppførsel avhengig av hvilken branch som oppdateres:
  - `main`-branch: Kjør `terraform apply` for å oppdatere infrastrukturen.
  - Andre branches: Kjør `terraform plan` for gjennomgang av endringer.

- **Lenker til kjørte Github Actions Workflows**:
  - [Terraform Apply Workflow (main)](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992557400)
  - [Terraform Plan Workflow (task2_branch_32)](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992157664)

- **Viktig**:
  - Relevant kode ligger i .github/workflows/deploy_terraform_32.yml
  
---

## Oppgave 3: Javaklient og Docker

### A. Dockerfile for Java-klient
- **Beskrivelse**: En Dockerfile er skrevet for å bygge og kjøre Java-klienten, som sender meldinger til SQS-køen. Dockerfile bruker en multi-stage tilnærming for å redusere bildestørrelse.
- 
- **Viktig**:
  - Relevant kode ligger i mappen java_sqs_client
  - Bilder som produseres via SQS-køen lagres i `s3://pgr301-couch-explorers/32/task2_generated_images`.

### B. GitHub Actions Workflow for publisering til Docker Hub
- **Beskrivelse**: Workflow som automatisk bygger og publiserer Docker-image til Docker Hub ved hver push til `main`-branchen.

#### **Container Image + SQS URL**
- **Image-Navn**: `borseharaldsen/sqs_client_32`
- **SQS URL**: `https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32`

#### **Taggestrategi**
Denne workflowen bruker en to-trinns taggestrategi for fleksibilitet og sporbarhet:
1. **`latest` tag**:
   - Docker-imaget tagges alltid med `latest` for å representere den nyeste og mest stabile versjonen.
   - Dette gjør det enkelt for utviklere og sensor å bruke standardversjonen uten å spesifisere en tag.

2. **Dynamisk tag basert på versjon og commit hash**:
   - **Format**: `${version}-${rev}`, der:
     - `version` er definert som en statisk versjon i workflowen (f.eks. `1.0.3`). Kan være fin måte å komme med "patches" og oppdateringer på, så man vet hvilken versjon man er på. 
     - `rev` er basert på en unik Git commit hash, generert med `git rev-parse --short HEAD`.
   - **Eksempel**: `1.0.3-abc123`.

#### **Fordeler med denne strategien**:
   - `latest` gir enkel tilgang til den nyeste versjonen for testing og bruk.
   - Dynamiske tagger sikrer sporbarhet, slik at spesifikke versjoner kan brukes for debugging eller historisk referanse.

- **Viktig**:
  - Relevant kode ligger i .github/workflows/docker_publish_32.yml

---

## Oppgave 4: Metrics og overvåkning

### CloudWatch Alarm
- **Beskrivelse**: En CloudWatch-alarm er konfigurert for å overvåke SQS-metrikken `ApproximateAgeOfOldestMessage`. Alarmen sender e-postvarsler når verdien overstiger en definert terskel (30 sekunder).

#### **Implementasjon**:
- **Navn på CloudWatch Alarm**:32-sqs-ApproximateAgeOfOldestMessage-alarm
- Terraform-koden fra oppgave 2 er utvidet med alarmoppsett.
- Alarmen er koblet til en SNS-topic som sender e-post til en adresse spesifisert i Terraform-variabelen `alarm_email`.
- **Terskelen**: Alarmen trigges dersom den eldste meldingen i køen er eldre enn **30 sekunder**.
  - Dette er basert på at de fleste bilder tar ca. 6 sekunder å generere, og en forsinkelse på 30 sekunder indikerer en betydelig flaskehals i systemet.
- **Evalueringstid**: Alarmen evalueres over én enkelt periode (30 sekunder) for å sikre rask varsling.
- **Testing**:
  - Kan enkelt testes ved å deaktivere "Event Source Mapping" på Lambda-funksjonen, sende meldinger til SQS-køen, og observere at alarmen trigges.

  - **Viktig**:
  - Relevant kode ligger i mappen infra.


## **Sammendrag av Leveranser**

| Oppgave   | Leveranse                                              |
|-----------|--------------------------------------------------------|
| Oppgave 1 | API Gateway URL: `https://dok2ppwzob.execute-api.eu-west-1.amazonaws.com/Prod/generate-image` |
|           | [GitHub Actions Workflow (SAM Deploy)](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992557403) |
| Oppgave 2 | SQS URL: `https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32` |
|           | [Terraform Apply Workflow](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992557400) |
|           | [Terraform Plan Workflow](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992157664) |
| Oppgave 3 | Container Image: `borseharaldsen/sqs_client_32`         |
|           | SQS URL: `https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32` |
| Oppgave 4 | CloudWatch alarm konfigurert i `infra`.                |
---