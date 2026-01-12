---
title: "Kontrolna lista za bezbednost i usklađenost veštačke inteligencije (AI)"
description: "Sveobuhvatna kontrolna lista za obezbeđivanje implementacija veštačke inteligencije (AI) u regulisanim industrijama i osiguravanje usklađenosti sa globalnim standardima."
date: "2024-03-20"
tags: ["Bezbednost", "Usklađenost", "GDPR", "Korporativni AI"]
---

# Kontrolna lista za bezbednost i usklađenost veštačke inteligencije (AI)

Kako veliki jezički modeli (LLM) prelaze iz istraživačkih laboratorija u korporativnu produkciju, površina napada na organizacije se proširila preko noći. Za regulisane industrije, izazov nije samo u tome da AI funkcioniše – već da bude **usklađen sa propisima**.

Ova kontrolna lista pruža putokaz za direktore bezbednosti informacija (CISO) i službenike za zaštitu podataka (DPO) kako bi revidirali svoju AI infrastrukturu u odnosu na globalne regulatorne okvire i savremene bezbednosne prakse.

## 1. Regulatorno mapiranje: GDPR, SOC2 i ISO

AI sistemi ne postoje u pravnom vakuumu. Postojeći okviri se direktno primenjuju na način na koji LLM modeli obrađuju podatke.

### GDPR Član 32 (Tehničke i organizacione mere)
- **Klasifikacija podataka**: Da li osiguravate da se zaštićene zdravstvene informacije (PHI) ili lični podaci (PII) ne koriste za obuku modela bez izričitog pristanka?
- **Pravo na brisanje**: Kako upravljate „zaboravljanjem“ podataka koji su uneti u vektorsku bazu podataka (RAG)?
- **Privatnost po dizajnu**: Da li je AI arhitektura izolovana (air-gapped) ili ograničena kako bi se sprečilo curenje podataka ka spoljnim provajderima API-ja?

### SOC2 kriterijumi poverenja (Bezbednost i privatnost)
- **Kontrola pristupa**: Da li su AI interfejsi za upite zaštićeni višefaktorskom autentifikacijom (MFA) i kontrolom pristupa zasnovanom na ulogama (RBAC)?
- **Revizorski tragovi**: Da li se svi parovi upita i odgovora beleže u nepromenljivu, enkriptovanu bazu podataka za forenzičku reviziju?

## 2. Tehničke bezbednosne kontrole

Sigurna implementacija zahteva prelazak sa sistema „crne kutije“ na transparentna, upravljana okruženja.

### Upravljanje ranjivostima
- **Automatsko skeniranje tajni**: Koristite alate kao što su Gitleaks ili TruffleHog kako biste osigurali da API ključevi, lozinke ili nizovi baza podataka nisu slučajno uključeni u upite ili sistemska uputstva.
- **Revizija zavisnosti**: Redovno skenirajte AI tehnološki skup (LangChain, LlamaIndex, PyTorch) na poznate CVE ranjivosti.

### „Prompt Injection“ i čišćenje unosa
- **OWASP Top 10 za LLM**: Prioritet dajte zaštiti od direktnog manipulisanja upitima (Prompt Injection - LLM01), gde korisnici zaobilaze sistemska uputstva da bi izvukli osetljive podatke.
- **Validacija izlaza**: Implementirajte zaštitni sloj („Guardian“) koji skenira kod ili tekst generisan od strane veštačke inteligencije na zlonamerne obrasce pre nego što stigne do krajnjeg korisnika.

### Mrežna filtracija i odlazni saobraćaj (Egress)
- **Zero-Trust VPC**: Server za AI zaključivanje nikada ne bi trebalo da ima direktan odlazni pristup internetu.
- **Odlazni proksiji**: Koristite transparentne proksije da dozvolite samo specifične krajnje tačke (endpoints) potrebne za ažuriranje modela ili ovlašćene spoljne konektore.

## 3. Upravljanje podacima u RAG sistemima

Generisanje prošireno pretraživanjem (RAG) je zlatni standard za korporativni AI, ali uvodi nove rizike od curenja podataka.

- **Atribucija izvora**: Svaki odgovor veštačke inteligencije mora da citira svoj izvor (npr. „Prema dokumentu X na strani Y“).
- **Dinamička sinhronizacija pristupa**: Ako korisnik nema dozvolu da čita „HR_Plate.pdf“, RAG sistem mora automatski da filtrira taj dokument iz rezultata vektorske pretrage u trenutku slanja upita.
- **Enkripcija vektorske baze**: Osigurajte da su vektorski „embeddings“ (koji su matematički prikazi vaših podataka) enkriptovani dok miruju (at rest).

## 4. Zahtev za ljudskim nadzorom (Human-in-the-Loop - HITL)

Automatizovani sistemi nikada ne bi trebalo da donose odluke od visokog značaja bez nadzora.

- **Povratne informacije**: Obezbedite mehanizam da korisnici prijave netačne ili pristrasne odgovore veštačke inteligencije.
- **Ručna revizija**: Visokorizične izlaze veštačke inteligencije (npr. pravni saveti, medicinski rezimei) trebalo bi periodično da revidiraju stručnjaci iz te oblasti.

## Zaključak

Usklađenost nije samo kvačica na papiru – to je kontinuirana inženjerska disciplina. Prateći ovaj putokaz, organizacije mogu iskoristiti moć LLM modela uz očuvanje poverenja svojih klijenata i odobrenje regulatora.

Inlock AI nudi automatizovano skeniranje usklađenosti i sigurne infrastrukturne šablone dizajnirane upravo za ove zahteve. [Kontaktirajte naš tim za bezbednost](file:///sr/auth/login) za potpunu reviziju vašeg trenutnog AI statusa.
