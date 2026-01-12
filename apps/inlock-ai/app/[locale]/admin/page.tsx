import { getDashboardData } from "@/src/lib/admin";
import { getCurrentUser } from "@/src/lib/auth";
import { redirect } from "next/navigation";
import { Card } from "@/components/ui/card";

export const dynamic = "force-dynamic";

export default async function AdminPage() {
  const user = await getCurrentUser();
  if (!user) {
    redirect("/auth/login");
  }

  const data = await getDashboardData();

  return (
    <div className="max-w-7xl mx-auto px-6 py-12 space-y-12">
      <section className="space-y-2">
        <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
          Admin Dashboard
        </h1>
        <p className="text-muted text-lg">
          Overview of contacts, leads, readiness assessments, and blueprints.
        </p>
      </section>

      {/* Summary Cards */}
      <section className="grid gap-4 md:grid-cols-4">
        <Card variant="elevated">
          <div className="space-y-2">
            <p className="text-sm text-muted">Contacts</p>
            <p className="text-3xl font-bold">{data.contacts.length}</p>
          </div>
        </Card>
        <Card variant="elevated">
          <div className="space-y-2">
            <p className="text-sm text-muted">Leads</p>
            <p className="text-3xl font-bold">{data.leads.length}</p>
          </div>
        </Card>
        <Card variant="elevated">
          <div className="space-y-2">
            <p className="text-sm text-muted">Readiness Assessments</p>
            <p className="text-3xl font-bold">{data.readinessCount}</p>
          </div>
        </Card>
        <Card variant="elevated">
          <div className="space-y-2">
            <p className="text-sm text-muted">Blueprints</p>
            <p className="text-3xl font-bold">{data.blueprintCount}</p>
          </div>
        </Card>
      </section>

      {/* Contacts Table */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Contacts</h2>
        {data.contacts.length === 0 ? (
          <Card variant="default">
            <p className="text-muted text-center py-8">No contacts yet.</p>
          </Card>
        ) : (
          <Card variant="elevated" className="overflow-hidden p-0">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-border">
                <thead className="bg-surface/50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Name
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Email
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Message
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Created
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {data.contacts.map((c) => (
                    <tr key={c.id} className="hover:bg-surface/30 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        {c.name}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-muted">
                        {c.email}
                      </td>
                      <td className="px-6 py-4 text-sm text-muted max-w-md">
                        <p className="line-clamp-2">{c.message}</p>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-xs text-muted">
                        {new Date(c.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        )}
      </section>

      {/* Leads Table */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Leads</h2>
        {data.leads.length === 0 ? (
          <Card variant="default">
            <p className="text-muted text-center py-8">No leads yet.</p>
          </Card>
        ) : (
          <Card variant="elevated" className="overflow-hidden p-0">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-border">
                <thead className="bg-surface/50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Name
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Email
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Company
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Note
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-muted uppercase tracking-wider">
                      Created
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {data.leads.map((lead) => (
                    <tr key={lead.id} className="hover:bg-surface/30 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        {lead.name || "—"}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-muted">
                        {lead.email}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-muted">
                        {lead.company || "—"}
                      </td>
                      <td className="px-6 py-4 text-sm text-muted max-w-md">
                        {lead.note ? (
                          <p className="line-clamp-2">{lead.note}</p>
                        ) : (
                          "—"
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-xs text-muted">
                        {new Date(lead.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        )}
      </section>
    </div>
  );
}
