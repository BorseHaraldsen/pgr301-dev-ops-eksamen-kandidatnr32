# PGR301 EKSAMEN 2024 Couch Explorers - Bærekraftig turisme fra sofakroken ! 

## Kandidatnummer 32 besvarelse.
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
  - Kan enkelt testes ved å deaktivere "Event Source Mapping" på Lambda-funksjonen, sende meldinger til SQS-køen, og observere at alarmen trigges. Eller ved å f.eks. ta treshold ned. 

  - **Viktig**:
  - Relevant kode ligger i mappen infra.

## Oppgave 5: Serverless, Function-as-a-Service (FaaS) vs Container-teknologi

### **Kort introduksjon**:

Implementasjonen av et system basert på serverless arkitektur med FaaS-tjenester som f.eks. AWS lambda og Amazon SQS, sammenlignet med en mikrotjenestearkitektur med container-teknologi har store virkninger på utfallet til systemet.
De to tilnærmingene påvirker flere sentrale DevOps-prinsipper på forskjellige måter, men jeg skal drøfte implikasjonene i lys av disse spesifikke prinsippene: CI/CD (Kontinuerlig Integrasjon / Kontinuerlig leveranse), Overvåkning, Skalerbarhet og Kostnadskontroll, Eierskap og Ansvar.

### 1. **Automatisering og kontinuerlig levering (CI/CD)**:
Automatisering og kontinuerlig levering er en sentral del av DevOps praksis. Serverless og mikrotjenestearkitektur påvirker hvordan automatisering og CI/CD-pipelines utformes og operer.
### **Serverless-arkitektur** 
Serverless-arkitektur fremhever modularitet. Hver funksjon kan distribueres individuelt, noe som gir organisasjonen muligheten til å iterere raskt på spesifikke deler av applikasjonen uten å måtte distribuere hele systemet. Dette passer særlig godt i miljøer med hyppige endringer og/eller i små teams. 
Slike oppdateringer kan distribueres gjennom en enkel CI/CD-pipeline.

#### **Fordeler**:
- **Forenklet distribusjon**: Serverless-tjenester som AWS Lambda (Serverløs datatjeneste som kjører koden din som svar på hendelser / utløser) er designet for små, selvstendige funksjoner som kan distribueres individuelt. Dette reduserer kompleksiteten ved å oppdatere applikasjonen, ettersom endringer kan deployes uten å påvirke resten av systemet. Funksjonene lastes opp direkte, og infrastrukturen håndteres automatisk av leverandøren.
- **Raskere utrulling**: Modulariteten til serverless-funksjoner gjør det mulig å implementere og rulle ut endringer raskt. Dette er særlig nyttig i agile utviklingsmiljøer, hvor små og hyppige oppdateringer er vanlige. Altså raske iterasjoner. CI/CD-pipelines kan raskt kjøre gjennom testing og utrulling for hver funksjon.
- **Kompleksitet**: Kompleksiteten er lavere, da man kan kjøre backend-kode uten å måtte administrere infrastruktur. Dette frigjør også tid til utviklere og administrasjon. 
- **Distribusjonsstrategier**: Serverless-arkitekturer har støtte for egne distribusjonsstrategier, slik som f.eks. "canary deployment". Dette kan automatisere prosessen enda mer, med lite ekstra arbeid eller konfigurasjon, noe som reduserer risiko for feil under deployment, med tanke på "skin in the game".

#### **Ulemper**:
- **Oversikt**: Når et system består av mange små funksjoner, kan det bli vanskelig å holde oversikt og administrere CI/CD pipelines effektivt. 
- **Feilhåndtering**: Feilhåndtering kan kreve mer innsats for å unngå store problemer. Feil i en funksjon kan ha innvirkning på andre funksjoner i systemet. Selv om de deployes individuelt, kan funksjonalitet slutte å fungere dersom koordineringen som er nødvendig mellom 2 eller flere funksjoner er feil. F.eks. feil i lambda funksjon kan ha innvirkning på produksjon av meldinger i en SQS-kø. 
- **Mangel på standardisering**: Ulike serverless-leverandører har forskjellige verktøy og prosesser, noe som kan gjøre det vanskelig å standardisere pipelines på tvers av miljøer. For eksempel kan overgangen fra AWS Lambda til en annen plattform kreve en betydelig omskriving av pipelines.
- **Avhengighet av tredjepart**: Fordi serverless-arkitekturen er sterkt knyttet til en spesifikk skyleverandør, blir CI/CD-prosessen også avhengig av leverandørens funksjoner og begrensninger. Dette kan gjøre det vanskeligere å implementere tilpasninger som passer prosjektets spesifikke behov. F.eks. kjøretidsbegrensninger (maks 15 minutter per kjøring) og ressursbegrensninger (minne opp til 10GB, begrenset diskplass).

### **Mikrotjenestearkitektur** 
Mikrotjenestearkitekturen bryter applikasjoner ned i mindre, selvstendige tjenester som kan utvikles, distribueres og skaleres uavhengig. Disse tjenestene er vanligvis pakket som containere og håndteres gjennom CI/CD-pipelines.
#### **Fordeler**:
- **Produktivitet**: Mikrotjenester er designet for å være uavhengige enheter som kan distribueres separat. Dette gir teamene mulighet til å jobbe parallelt på forskjellige tjenester, noe som øker produktiviteten i større team.
- **Konsistens/portabilitet**: Docker containere kjører identisk på ulike miljøer, uavhengig av operativsystem eller andre avhengigheter. Man kan også etablere standarder i containere, som gir bedre kontroll over distribusjonsprosessen og portabiliteten på tvers av miljøer.
- **Feilhåndtering**: Feil i én mikrotjeneste påvirker ikke nødvendigvis resten av systemet. Dette reduserer risikoen for at en enkelt feil sprer seg til hele applikasjonen.
- **Frihet**: Man er ikke låst til serverless-leverandører, som skaper mer frihet generelt, i teknologi og andre ting. Mer kontroll og fleksibilitet.

#### *Ulemper*:
- **Kompleksitet**: CI/CD-pipelines må settes opp for hver tjeneste, noe som kan føre til administrativ overbelastning, spesielt i større systemer. 
- **Administrivt arbeid**: Man må administrere infrastruktur, slik som f.eks. sikkerhet og andre ting, noe som kan ha påvirkning på automatisering og CI/CD. 
- **Iterasjonshastighet**: Mer omfattende oppsett og arbeid, generelt tregere iterasjoner. 

**Sammenligning og konklusjon**

Begge arkitekturer har unike styrker og svakheter når det gjelder automatisering og CI/CD.
Serverless kan være spesielt egnet for hendelsesdrevne, kostnadssensitive applikasjoner med uforutsigbare arbeidsmengder, som for eksempel IoT- eller mobilapplikasjonsbackends. Eller i vårt tilfelle image generating.
Mikrotjenester derimot, utmerker seg i storskala systemer som krever avansert kontroll og integrasjon, som for eksempel bedriftsapplikasjoner med ulike domene-spesifikke krav.
Valget mellom de to bør baseres på prosjektets størrelse, teamets behov og ønsket balanse mellom modularitet, kompleksitet og kontroll.
Uansett valg, må DevOps-prinsipper for automatisering og CI/CD tilpasses for å møte utfordringene i den valgte arkitekturen.

2. **`Observability (overvåkning)`**:
Overvåkning er en viktig del av DevOps-praksis, da det gir innsikt i systemets helse, ytelse og feilhåndtering. Forskjellen mellom container-basert mikrotjenestearkitektur og serverless-arkitektur har betydelige implikasjoner for hvordan observability håndteres.
- **Serverless-arkitektur**
Serverless-arkitektur er sterkt avhengig av skyleverandørens innebygde verktøy for overvåkning og logging.
- *Fordeler*:
- Innebygde overvåkingsverktøy: Serverless-plattformer som AWS Lambda har integrerte overvåkings- og loggingsfunksjoner gjennom tjenester som AWS CloudWatch og X-ray. Dette gjør det enkelt å samle metrikker, feilmeldinger og sporingsdata uten ekstra oppsett.
- Skalerbar overvåkning: Fordi serverless-arkitekturen skalerer automatisk, kan overvåkningen tilpasses denne skalerbarheten uten behov for manuell konfigurering.
- Mindre kompleksitet: Ved at infrastrukturen håndteres av leverandøren, reduseres kompleksiteten for utviklingsteamet. Behøver ikke overvåke fysiske servere, containere eller andre ting. 
- *Ulemper*:
Fragmentert logging: Hver funksjon genererer egne logger, noe som kan gjøre det utfordrene å følge en hel prosess som går gjennom flere funksjoner.
Mangel på tilpasning: Innebygde overvåkingsverktøy er begrenset til det leverandøren tilbyr. Hvis spesialtilpassede metrikker eller avanserte feilsøkingsmuligheter trengs, som ikke finnes hos leverandøren, kan det være vanskelig å implementere.
Asynkrone problemer: Feil som oppstår i asynkrone systemer (for eksempel når meldinger ligger i kø i SQS) kan være vanskelig å spore og feilsøke. Dette gjør debugging mer komplekst sammenlignet med synkrone mikrotjenester.
- **Mikrotjenestearkitektur**
- *Fordeler*:
- Fleksibilitet: Med mikrotjenester kan teamet fritt velge selv hvilket overvåkningsverktøy de ønsker, basert på behov. Dette kan gi full kontroll på hvordan man samler metrikker, visualiserer dem og analyserer. 
- Sentralisert logging: Man kan sentralisere loggingen sin for enkel sporing av prosesser.
- Alarmer: Man kan sette opp alarmer slik som med serverless-platformer, men man er ikke låst til det leverandøren tilbyr, som betyr at man kan ha hyperspesifikke alarmer.
- *Ulemper*:
- Kompleksitet: Oppsett av logging, og overvåking, er veldig mye mer krevende enn å bruke innebygde overvåkningsverktøy. Oppsettet krever mye tid og ressurser, særlig hvis tjeneste skalerer. 
- Støy: Hvis oppsettet ikke er optimalt, kan det være vanskelig å finne relevante logger eller metrics i store mengder data. 

**Sammenligning og konklusjon**
Serverless-arkitektur gir enkelhet og skalerbarhet, men på bekostning av fleksibilitet. Innebygde verktøy som CloudWatch gjør det raskt og enkelt å sette opp overvåkning, men utfordringer som fragmenterte logger og begrenset tilpasning kan redusere effektiviteten i komplekse systemer. 

Mikrotjenestearkitektur, på den andre siden, gir større kontroll og tilpasningsmuligheter. Dette gjør det mulig å implementere overvåkning som er skreddersydd til prosjektets behov. Likevel kommer dette med økt kompleksitet og kostnad, siden teamet selv må vedlikeholde overvåkningsinfrastrukturen.

Valget bør baseres på prosjektets størrelse og krav til overvåkning, samt teamets kapasitet til å vedlikeholde overvåkningsinfrastrukturen. 
For Couch Explorers-prosjektet, hvor bildeskaping er sentralt, kan serverless være et godt valg på grunn av sin innebygde støtte for logging og skalerbarhet, men mer spesialiserte mikrotjenestebaserte løsninger kan vurderes for områder som brukeradministrasjon eller betalingssystemer.
3. **`Skalerbarhet og kostnadskontroll:`**:
Skalerbarhet og kostnadskontroll er avgjørende faktorer ved valg av arkitektur. Serverless og mikrotjenestearkitekturer har ulike egenskaper når det gjelder ressursutnyttelse, automatisering av skalering og økonomisk effektivitet.
- **Serverless-arkitektur**
Serverless-arkitekturer er designet for automatisk skalering, hvor ressurser tildeles dynamisk basert på faktisk belastning.
- *Fordeler*:
- Automatisk skalering: AWS Lambda og lignende tjenester skalerer automatisk opp og ned basert på trafikk. Dette gjør det mulig å håndtere plutselige økninger i bruk uten å konfigurere eller overvåke servere manuelt.
- Skalerbarhet: Håndterer også automatisk tusenvis av samtidige forespørsler. Betyr at det er veldig skalerbart. 
- Redusert kompleksitet/administrasjon: Ingen servervedlikehold, som igjen gjør at kostnad og ressurser blir lave dersom det skaleres høyt. 
- Ingen kostnad ved inaktivitet: Funksjoner faktureres kun når de kjører (betaler kun for datakraften du bruker i millisekunder), noe som betyr at kostnadene skalerer med bruken.
- Ressurser: Ressurser (CPU og minne) blir tildelt hver funksjon dynamisk, noe som eliminerer overprovisjonering.
- *Ulemper*:
- Cold Starts: Det kan forekomme forsinkelse ved første oppstart til en funksjon. Dette fører til økt responstid, som kan være kritisk i visse applikasjoner, da særlig hvis det er skalert stort.
- Kjøretidsbegrensninger, ressursbegrensninger og stateless: Maks 15 min per kjøring, må bruke ekstern lagring, minne opptil 10gb og begrenset diskplass, kan ha komplikasjoner ved skalering og/eller ressurskrevende applikasjoner.
- Kostnader ved kontinuerlig bruk: For arbeidsmengder med konstant høy trafikk, kan potensielet kostnadene for serverless overstige kostnadene ved å drifte egne servere eller containere, da betalingen skjer per datakraft som brukes.
- **Mikrotjenestearkitektur**:
Containerbaserte Mikrotjenestearkitekturer, gir organisasjonen full kontroll over ressursene og hvordan tjenestene skaleres.
- *Fordeler*:
- Portabilitet og konsistens: Som nevnt tidligere, docker kontainere kjører identisk på ulike miljøer, som kan være gunstig under skalering av et stort system.
- Isolasjon: Da hver applikasjon og dens avhengigheter er isolert i egen container, forhindrer du konflikter i store systemer.
- Skalerbarhet: Docker gjør det enkelt å distribuere og skalere applikasjoner ved å kjøre flere instanser av en container på tvers av ulike servere.
- Standardisert orkistrering: Håndtering av applikasjoner er standardisert. 
- Ressurser: Siden docker-containere deler kjerne med operativsystemet, kan en kjøre flere applikasjoner med lavt ressursbruk. Dette optimaliserer serverressurser. 
- Kostnader: Ved jevn og høy arbeidsbelastning i store systemer kan drift av containere være billigere enn serverless, da det kan redusere kostnadene ved konstante hyppige forespørsler.
- *Ulemper*:
- Manuell skalering: For å håndtere "spikes" i trafikken må man ofte ha ekstra ressurser aktive in case det trengs. Dette fører til ressurser og kostnader som står ubrukt i perioder med enten lav eller ingen belastning.
- Kompleksitet: Mikrotjenestearkitektur krever administrativt arbeid og manuelle skaleringsstrategier, noe som øker kompleksitet og vedlikeholdskostnader. 
- Fast kostnad. Selv når containerbasert systemer ikke brukes må man ofte betale for drift av server 24/7, selv under inaktivitet. 

**Sammenligning og konklusjon**
Serverless gir en enkel og automatisk skalering som er ideell for applikasjoner med uforutsigbar trafikk, som sporadiske batch-jobber eller brukergenererte forespørsler. 
Serverless er svært kostnadseffektivt for applikasjoner med lav eller variabel trafikk, da man kun betaler for faktisk bruk.
Serverless er ideelt for applikasjoner som ikke krever kontinuerlig drift eller brukerintensive ressurser.

Mikrotjenester gir derimot bedre kontroll over hvordan og når tjenester skaleres, noe som er nyttig for systemer med klare krav til ytelse.
For applikasjoner med jevn og høy trafikk kan mikrotjenester være billigere, siden faste ressurskostnader kan utnyttes bedre.
Mikrotjenester gir fordelen av å optimalisere ressursbruken ved å tildele nøyaktig det som trengs for hver tjeneste.

4. **`Eierskap og ansvar`**:
Eierskap og ansvar handler om hvordan teamet håndterer applikasjonens ytelse, pålitelighet og kostnader, og hvordan dette påvirkes av arkitekturvalget.
- **Serverless-arkitektur**
I en serverless-arkitektur ligger mye av ansvaret for infrastruktur og vedlikehold hos skyleverandøren. Dette reduserer teamets eierskap til infrastrukturen, men gir fortsatt utviklerne ansvar for applikasjonens funksjonalitet.
- *Ytelse*:
- Skyleverandøren håndterer ressursallokering og automatisk skalering, noe som betyr at teamet ikke trenger å justere CPU eller minne manuelt.
- Begrenset kontroll over infrastrukturen kan føre til utfordringer i optimalisering av ytelsen, særlig med kaldstart-latens som er et unikt problem i serverless-systemer.
- Teamets ansvar: Optimalisere koden for rask respons og minimal kjøretid og monitorere ytelsen ved hjelp av leverandørens verktøy (f.eks. AWS CloudWatch) for å identifisere flaskehalser i funksjonene.
- *Pålitilighet*:
- Service Level Agreements (SLA-er) fra skyleverandøren sikrer høy oppetid, men teamet må fortsatt håndtere feil på applikasjonsnivå.
- Forenklet vedlikehold: Ingen behov for å administrere servere eller overvåke infrastruktur. Dette eliminerer risikoen for feilkonfigurasjoner av servere.
- Teamets ansvar: Designe robuste systemer som håndterer feil. Konfigurere retries og fallback-mekanismer for funksjoner og køer.
- *Kostnader*:
- Kostnader er knyttet til faktisk bruk (betal-per-forespørsel), noe som gjør dem dynamiske og potensielt uforutsigbare.
- Ueffektiv koding eller bruk av funksjoner, som for mange kaldstarter, kjøretid, eller overflødige kall, kan føre til unødvendige utgifter.
- Teamets ansvar: Analysere og optimalisere funksjoners kjøretid. Unngå unødvendige kall og overprovisjonering av ressurser.

- **Mikrotjenestearkitektur**:
I en mikrotjeneste-arkitektur ligger full kontroll over infrastrukturen og applikasjonens drift hos teamet. Dette gir større eierskap, men krever også mer ressurser og oppfølging.
- *Ytelse*:
- Teamet kan konfigurere tjenester for å oppnå spesifikke ytelsesmål, inkludert skalering og ressursbruk, uten å være begrenset av leverandørens standarder.
- Feil eller ineffektiv ressursbruk kan føre til dårlig ytelse og nedetid.
- Teamets ansvar: Administrere servere eller containere for å sikre at ressursene er riktig konfigurert og tilstrekkelige for å møte trafikkbehov. Overvåke og justere skalering for å oppnå optimal ytelse.
- *Pålitilighet*:
- Pålitelighet er helt avhengig av teamets design og implementering av redundans, vedlikehold og overvåkning.
- Mer "Head in the Game".
- Pålitiligheten avhenger av hvordan organisasjonen har utviklet systemet, og om det fungerer slik det skal. 
- Isolasjon: Feil i én tjeneste påvirker vanligvis ikke andre tjenester, gitt god design. Dette gir teamet bedre kontroll over applikasjonens pålitelighet.
- Teamets ansvar: Sørge for at tjenester er isolerte og designet for å håndtere feil uten å forårsake systemfeil. Implementere overvåkning og alarmer for tidlig oppdagelse av problemer.
- *Kostnader*:
- Kostnader er ofte faste, basert på driften av servere og containere, noe som gir bedre forutsigbarhet, men høyere grunnkostnader.
- Overprovisjonering eller ineffektiv ressursbruk kan føre til sløsing.
- Feil i infrastruktur eller konfigurasjon kan føre til nedetid og økonomiske tap. Dette kan også kreve økt bemanning for å håndtere feilretting.
- Teamets ansvar: Planlegge og allokere ressurser basert på forventet bruk. Optimalisere tjenestene for å redusere behovet for overprovisjonering.

**Sammenligning og konklusjon**
Serverless reduserer teamets eierskap til infrastruktur og ytelse, men beholder ansvaret for kostnadskontroll og optimalisering av funksjoner. 
Dette kan være utfordrende i systemer med høye krav til ytelse og forutsigbare kostnader.
Mikrotjenester gir større eierskap over hele systemet, men medfører mer ansvar for vedlikehold, ytelse, kostnader og feilhåndtering. Dette krever dedikerte ressurser og større teamkapasitet.





## **Sammendrag av Leveranser**

| *Oppgave*   | *Leveranse*                                              |
|-----------|--------------------------------------------------------|
| **Oppgave 1** | API Gateway URL: `https://dok2ppwzob.execute-api.eu-west-1.amazonaws.com/Prod/generate-image` |
|           | [GitHub Actions Workflow (SAM Deploy)](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992557403) |
| **Oppgave 2** | SQS URL: `https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32` |
|           | [Terraform Apply Workflow](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992557400) |
|           | [Terraform Plan Workflow](https://github.com/BorseHaraldsen/pgr301-dev-ops-eksamen-kandidatnr32/actions/runs/11992157664) |
| **Oppgave 3** | Container Image: `borseharaldsen/sqs_client_32`         |
|               | SQS URL: `https://sqs.eu-west-1.amazonaws.com/244530008913/terraform-sqs-queue-32` |
| **Oppgave 4** | CloudWatch alarm konfigurert i `infra`.                |
| **Oppgave 5** | Drøfting av serverless og mikrotjenester. |
---