import { Card } from "@/components/ui/card";

const sections = [
  {
    title: "Pre-Deployment Security",
    summary:
      "Baseline controls before any model touches production data. Confirm data classification, RBAC, and network isolation are locked in.",
    areas: [
      {
        title: "Data Classification",
        items: [
          "Classify every dataset (public, internal, restricted).",
          "Map PII/PHI locations and retention timelines.",
          "Document data flows between connectors and workspaces.",
        ],
      },
      {
        title: "Access Controls",
        items: [
          "Role-based access with least privilege enforced.",
          "Mandatory MFA + session timeouts for admin planes.",
          "Quarterly access audits tied to workspace rosters.",
        ],
      },
      {
        title: "Infrastructure",
        items: [
          "Segment AI runtime networks; no flat VPCs.",
          "TLS 1.3 everywhere, including internal service mesh.",
          "API auth + rate limiting + DDoS guardrails enabled.",
        ],
      },
    ],
  },
  {
    title: "Data Protection",
    summary: "Keep sensitive knowledge encrypted, minimized, and resident in approved regions.",
    areas: [
      {
        title: "Encryption",
        items: [
          "AES-256 at rest + TLS in transit, documented standards.",
          "Managed keys (HSM/KMS) with rotation playbooks.",
          "Immutable logs proving key lifecycle events.",
        ],
      },
      {
        title: "Minimization",
        items: [
          "Collect only fields needed for a given template.",
          "Automated retention + deletion tied to workspace policy.",
          "Quarterly data hygiene reviews to purge stale caches.",
        ],
      },
      {
        title: "Residency",
        items: [
          "Map jurisdictions + geo-fence inference workloads.",
          "Document cross-border transfers and lawful basis.",
          "Run compliance spot-checks on storage locations.",
        ],
      },
    ],
  },
  {
    title: "Model Security",
    summary: "Protect model artifacts, inputs, and outputs against extraction, abuse, and injections.",
    areas: [
      {
        title: "Model Protection",
        items: [
          "Versioned, access-controlled model registry.",
          "Automated scans for model exfiltration anomalies.",
          "Scheduled red-team exercises on model endpoints.",
        ],
      },
      {
        title: "Input Validation",
        items: [
          "Sanitize and schema-validate every request.",
          "Apply throttling per workspace + IP.",
          "Alert on prompt-injection heuristics.",
        ],
      },
      {
        title: "Output Guardrails",
        items: [
          "Sensitive-term filters before results reach users.",
          "Watermarking / provenance metadata appended.",
          "Content moderation hooks for public-facing flows.",
        ],
      },
    ],
  },
  {
    title: "Compliance Pillars",
    summary: "Translate regulation into actionable controls for GDPR, HIPAA, SOX/PCI, and industry mandates.",
    areas: [
      {
        title: "GDPR + Privacy",
        items: [
          "Lawful basis + DPIA for each workspace dataset.",
          "Self-service data-subject workflows (export/delete).",
          "Privacy-by-design reviews on new templates.",
        ],
      },
      {
        title: "HIPAA / PHI",
        items: [
          "Business Associate Agreements with providers.",
          "Encrypted PHI everywhere + tamper-proof audit logs.",
          "Staff training + attestation for clinical teams.",
        ],
      },
      {
        title: "Financial / Industry",
        items: [
          "SOX/PCI transaction logging + reconciliation.",
          "Documented model-risk governance board.",
          "Reg-change tracking with mapped controls.",
        ],
      },
    ],
  },
  {
    title: "Monitoring & Auditing",
    summary: "Turn telemetry into signal: unified logging, anomaly detection, and scheduled audits.",
    areas: [
      {
        title: "Logging",
        items: [
          "Immutable logs for auth, data access, model runs.",
          "Retention windows match regulatory rules.",
          "Centralized lake with least-privilege readers.",
        ],
      },
      {
        title: "Observability",
        items: [
          "Real-time alerts on RBAC or data spikes.",
          "Baseline model drift + hallucination monitors.",
          "Usage dashboards per workspace for sponsors.",
        ],
      },
      {
        title: "Audits",
        items: [
          "Quarterly security/compliance walkthroughs.",
          "Access log spot-checks with remediation tracking.",
          "Documented findings tied to owners + due dates.",
        ],
      },
    ],
  },
  {
    title: "Incident Response",
    summary: "Assume breach. Design drills, escalation paths, and communications tailored to AI workloads.",
    areas: [
      {
        title: "Preparation",
        items: [
          "AI-specific runbooks with workspace context.",
          "Named on-call roles + contact ladders.",
          "Tabletop exercises each quarter.",
        ],
      },
      {
        title: "Response",
        items: [
          "Rapid isolation tooling (revoke tokens, pause models).",
          "Template communications for regulators + clients.",
          "Forensics pipeline capturing prompts + outputs.",
        ],
      },
    ],
  },
  {
    title: "Vendors & People",
    summary: "Supply-chain trust plus a trained workforce keeps pilots resilient.",
    areas: [
      {
        title: "Vendor Governance",
        items: [
          "Security questionnaires + certification reviews.",
          "Data Processing Agreements with breach clauses.",
          "Recurring reassessments for high-risk providers.",
        ],
      },
      {
        title: "Training & Awareness",
        items: [
          "Role-specific security training (ops, legal, eng).",
          "Documented policies + searchable runbooks.",
          "Culture of reporting near-misses + lessons learned.",
        ],
      },
    ],
  },
];

const toAnalyticsId = (prefix: string, title: string) =>
  `${prefix}-${title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`;

export function SecurityChecklist({ analyticsPrefix = "security-checklist" }: { analyticsPrefix?: string }) {
  return (
    <div className="space-y-12">
      <Card
        padding="none"
        className="bg-surface border border-border/60 p-8 space-y-4"
        data-analytics-id={`${analyticsPrefix}-intro`}
      >
        <p className="text-sm uppercase tracking-[0.2em] text-primary font-semibold">Inlock Control Stack</p>
        <h2 className="text-3xl font-semibold tracking-tight">AI Security & Compliance Checklist</h2>
        <p className="text-muted text-lg leading-relaxed">
          Use this to pressure-test each workspace before go-live. Every item maps back to Inlock&apos;s governed defaults
          so sponsors can prove provenance and regulators can trace controls.
        </p>
      </Card>

      {sections.map((section) => (
        <section
          key={section.title}
          className="rounded-3xl border border-border/60 bg-surface/80 backdrop-blur-xl p-6 sm:p-8 space-y-6"
          data-analytics-id={toAnalyticsId(analyticsPrefix, section.title)}
        >
          <div className="flex flex-col gap-4 sm:flex-row sm:items-baseline sm:justify-between">
            <h3 className="text-2xl sm:text-3xl font-semibold tracking-tight">{section.title}</h3>
            <p className="text-muted text-base max-w-2xl leading-relaxed">{section.summary}</p>
          </div>
          <div className="grid gap-5 sm:gap-6 md:grid-cols-2 lg:grid-cols-3">
            {section.areas.map((area) => (
              <div
                key={area.title}
                className="rounded-2xl border border-border/40 bg-background/60 p-5 space-y-4 shadow-apple"
                data-analytics-id={toAnalyticsId(analyticsPrefix, `${section.title}-${area.title}`)}
              >
                <h4 className="text-lg font-semibold flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-primary/70" />
                  {area.title}
                </h4>
                <ul className="space-y-3 text-muted">
                  {area.items.map((item) => (
                    <li key={item} className="flex items-start gap-3">
                      <span className="mt-1 inline-flex h-5 w-5 items-center justify-center rounded-full border border-primary/50 text-xs text-primary">
                        ✓
                      </span>
                      <span className="flex-1 leading-relaxed">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>
      ))}

      <Card
        padding="none"
        className="bg-gradient-to-r from-primary/20 via-accent/10 to-primary/20 border border-primary/40 p-8 space-y-4"
        data-analytics-id={`${analyticsPrefix}-next-steps`}
      >
        <h3 className="text-2xl font-semibold">Operational next steps</h3>
        <p className="text-muted text-base leading-relaxed">
          Turn this checklist into tracked work: link each item to owners, attach evidence (policy docs, screenshots,
          audit reports), and review status during every Transformation Cockpit meeting. Governance only works when it is
          visible.
        </p>
      </Card>
    </div>
  );
}



