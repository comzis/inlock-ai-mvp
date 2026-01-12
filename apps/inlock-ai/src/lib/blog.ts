export interface BlogMeta {
  slug: string;
  title: string;
  date: string;
  readTime: string;
  excerpt: string;
  file: string;
  pillars: string[];
  productAngle: string;
  locales?: {
    [key: string]: {
      excerpt: string;
      productAngle: string;
      title?: string;
    };
  };
}

export const blogPosts: BlogMeta[] = [
  {
    slug: "local-vs-cloud-ai",
    title: "Local vs Cloud AI for Regulated Industries",
    date: "2025-01-10",
    readTime: "6 min read",
    excerpt:
      "A practical overview of when to choose local AI over cloud offerings, especially under GDPR and strict compliance.",
    file: "local-vs-cloud-ai.md",
    pillars: ["Deployment flexibility", "Data locality", "Governance & risk"],
    productAngle:
      "Helps sponsors decide on on-prem vs cloud while keeping workspace isolation, auditability, and data-residency commitments front-and-center.",
    locales: {
      fr: {
        title: "IA locale vs IA cloud pour les industries réglementées",
        excerpt: "Un aperçu pratique pour choisir entre l'IA locale et les offres cloud, en particulier sous le RGPD et une conformité stricte.",
        productAngle: "Aide les sponsors à décider entre sur site et cloud tout en maintenant l'isolation de l'espace de travail, l'auditabilité et les engagements de résidence des données au premier plan."
      },
      sr: {
        title: "Lokalni naspram Cloud AI za regulisane industrije",
        excerpt: "Praktičan pregled kada odabrati lokalni AI umesto cloud ponuda, posebno pod GDPR-om i strogom usklađenošću.",
        productAngle: "Pomaže sponzorima da odluče između on-prem i cloud rešenja uz zadržavanje izolacije radnog prostora, revizije i posvećenosti rezidentnosti podataka u prvom planu."
      }
    }
  },
  {
    slug: "on-premise-llm-deployment",
    title: "On-Premise LLM Deployment: A Complete Guide",
    date: "2025-01-15",
    readTime: "12 min read",
    excerpt:
      "A step-by-step guide to deploying large language models entirely within your infrastructure for maximum security and compliance.",
    file: "on-premise-llm-deployment.md",
    pillars: ["Deployment flexibility", "Security baseline", "Model agnostic"],
    productAngle:
      "Shows how to run Inlock's stack privately with pluggable providers, RBAC, and workspace-scoped configuration per Inlock solution §§5–6.",
    locales: {
      fr: {
        title: "Déploiement de LLM sur site : Un guide complet",
        excerpt: "Un guide étape par étape pour déployer de grands modèles de langage entièrement au sein de votre infrastructure pour une sécurité et une conformité maximales.",
        productAngle: "Montre comment exécuter la pile Inlock en privé avec des fournisseurs connectables, RBAC et une configuration par espace de travail selon la solution Inlock §§5–6."
      },
      sr: {
        title: "Implementacija LLM modela lokalno: Vodič za regulisane industrije",
        excerpt: "Naučite kako da implementirate velike jezičke modele (LLM) lokalno kako biste osigurali privatnost podataka i usklađenost sa propisima u vašoj organizaciji.",
        productAngle: "Pokazuje kako pokrenuti Inlock stack privatno sa priključivim provajderima, RBAC-om i konfiguracijom obima radnog prostora prema Inlock rešenju §§5–6."
      }
    }
  },
  {
    slug: "rag-implementation-best-practices",
    title: "RAG Implementation Best Practices for Enterprise",
    date: "2025-01-20",
    readTime: "15 min read",
    excerpt:
      "Learn how to build production-ready Retrieval-Augmented Generation systems that are secure, accurate, and maintainable.",
    file: "rag-implementation-best-practices.md",
    pillars: ["Knowledge & data layer", "RAG quality", "Provenance"],
    productAngle:
      "Aligns with unified indexing, chunking, and cited answers so pilots can trust retrieval quality and avoid vendor lock-in for embeddings or vector stores.",
    locales: {
      fr: {
        title: "Meilleures pratiques pour l'implémentation du RAG en entreprise",
        excerpt: "Apprenez à construire des systèmes de génération augmentée par récupération prêts pour la production, sécurisés, précis et maintenables.",
        productAngle: "S'aligne avec l'indexation unifiée, le découpage et les réponses citées pour que les pilotes puissent faire confiance à la qualité de récupération et éviter le verrouillage fournisseur."
      },
      sr: {
        title: "Najbolje prakse za RAG implementaciju",
        excerpt: "Najbolje prakse za implementaciju generisanja proširenog pretraživanjem (RAG) za privatne AI sisteme spremne za produkciju.",
        productAngle: "Usklađuje se sa objedinjenim indeksiranjem, komadanjem i citiranim odgovorima tako da piloti mogu verovati kvalitetu pretraživanja i izbeći zaključavanje kod dobavljača."
      }
    }
  },
  {
    slug: "ai-security-compliance-checklist",
    title: "AI Security and Compliance Checklist for Regulated Industries",
    date: "2025-01-22",
    readTime: "10 min read",
    excerpt:
      "A comprehensive checklist to ensure your AI deployments meet security and compliance requirements.",
    file: "ai-security-compliance-checklist.md",
    pillars: ["Security baseline", "Governance & RBAC", "Workspace isolation"],
    productAngle:
      "Maps to Inlock's governed defaults: RBAC, auditability, and strict data handling across connectors, indexing, and model access.",
    locales: {
      fr: {
        title: "Liste de contrôle de sécurité et de conformité de l'IA",
        excerpt: "Une liste de contrôle complète pour garantir que vos déploiements d'IA répondent aux exigences de sécurité et de conformité.",
        productAngle: "Cartographie les paramètres par défaut régis d'Inlock : RBAC, auditabilité et gestion stricte des données à travers les connecteurs, l'indexation et l'accès aux modèles."
      },
      sr: {
        title: "Kontrolna lista za bezbednost i usklađenost veštačke inteligencije (AI)",
        excerpt: "Sveobuhvatna kontrolna lista za obezbeđivanje implementacija veštačke inteligencije (AI) u regulisanim industrijama i osiguravanje usklađenosti sa globalnim standardima.",
        productAngle: "Mapira se na Inlock podrazumevane vrednosti upravljanja: RBAC, revizija i strogo rukovanje podacima kroz konektore, indeksiranje i pristup modelima."
      }
    }
  },
  {
    slug: "cost-comparison-local-vs-cloud-ai",
    title: "Cost Comparison: Local vs Cloud AI for Enterprise",
    date: "2025-01-25",
    readTime: "14 min read",
    excerpt:
      "A detailed financial analysis to help you make informed decisions about AI infrastructure investments.",
    file: "cost-comparison-local-vs-cloud-ai.md",
    pillars: ["Cost transparency", "Deployment flexibility", "Pilot ROI"],
    productAngle:
      "Supports success metrics by clarifying TCO for on-prem vs cloud while keeping the architecture modular enough to switch providers later.",
    locales: {
      fr: {
        title: "Comparaison des coûts : IA locale vs IA cloud",
        excerpt: "Une analyse financière détaillée pour vous aider à prendre des décisions éclairées concernant les investissements en infrastructure d'IA.",
        productAngle: "Soutient les mesures de succès en clarifiant le TCO pour le sur site vs cloud tout en gardant l'architecture assez modulaire pour changer de fournisseur plus tard."
      },
      sr: {
        title: "Poređenje troškova: Lokalni vs. Cloud AI",
        excerpt: "Detaljna analiza ukupnih troškova vlasništva za lokalne AI implementacije u poređenju sa alternativama zasnovanim na oblaku.",
        productAngle: "Podržava metriku uspeha razjašnjavanjem TCO-a za lokalno vs cloud rešenje, uz održavanje modularne arhitekture koja omogućava kasniju promenu provajdera."
      }
    }
  },
  {
    slug: "building-private-ai-assistants",
    title: "Building Private AI Assistants: Architecture and Best Practices",
    date: "2025-01-28",
    readTime: "18 min read",
    excerpt:
      "Learn how to design and deploy secure, private AI assistants that keep your data within your infrastructure.",
    file: "building-private-ai-assistants.md",
    pillars: ["Model orchestration", "Templates", "Human-in-the-loop"],
    productAngle:
      "Connects to Inlock solution templates, routing policies, and review flows so assistants stay governed, cited, and workspace-aware.",
    locales: {
      fr: {
        title: "Création d'assistants IA privés : Architecture et meilleures pratiques",
        excerpt: "Apprenez à concevoir et déployer des assistants IA privés et sécurisés qui conservent vos données au sein de votre infrastructure.",
        productAngle: "Se connecte aux modèles de la solution Inlock, aux politiques de routage et aux flux de révision pour que les assistants restent gouvernés, cités et conscients de l'espace de travail."
      },
      sr: {
        title: "Izgradnja privatnih AI asistenata uz Inlock AI",
        excerpt: "Otkrijte kako Inlock AI omogućava kreiranje moćnih, privatnih AI asistenata koji koriste interno znanje vaše organizacije na bezbedan način.",
        productAngle: "Povezuje se sa Inlock šablonima rešenja, smernicama rutiranja i tokovima pregleda tako da asistenti ostaju pod upravom, citirani i svesni radnog prostora."
      }
    }
  },
];

export function getAllBlogPosts(): BlogMeta[] {
  return blogPosts;
}

export function getBlogPostBySlug(slug: string, locale: string = "en"): BlogMeta | undefined {
  const post = blogPosts.find((p) => p.slug === slug);
  if (!post) return undefined;

  let localized = { ...post };

  // Apply localization if available
  if (locale !== "en" && post.locales && post.locales[locale]) {
    const loc = post.locales[locale];
    if (loc.title) localized.title = loc.title;
    if (loc.excerpt) localized.excerpt = loc.excerpt;
    if (loc.productAngle) localized.productAngle = loc.productAngle;
  }

  // localized file path logic
  localized.file = locale === "en" ? `${slug}.md` : `${slug}.${locale}.md`;

  return localized;
}
