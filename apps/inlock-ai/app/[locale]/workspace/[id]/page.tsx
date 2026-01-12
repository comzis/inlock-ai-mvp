import { getWorkspace } from "@/src/lib/workspace";
import { redirect } from "next/navigation";
import { FileText, Database, MessageSquare, Clock } from "lucide-react";

export default async function WorkspaceDashboard({
    params,
}: {
    params: Promise<{ id: string }>;
}) {
    const { id } = await params;

    // Auth check again? Layout handles it, but page also runs.
    // We can skip heavy auth check if we trust layout, but good practice to check or pass data.
    // For MVP, I'll assume layout protects it or just fetch data.
    // I need user ID for getWorkspace.

    const { cookies } = await import("next/headers");
    const cookieStore = await cookies();
    const token = cookieStore.get("session_token")?.value;
    const { prisma } = await import("@/src/lib/db");

    if (!token) redirect("/login");
    const session = await prisma.session.findUnique({ where: { token }, select: { userId: true } });
    if (!session) redirect("/login");

    const workspace = await getWorkspace(id, session.userId);
    if (!workspace) redirect("/workspace");

    const stats = [
        { label: "Documents", value: workspace._count.documents, icon: FileText, color: "bg-blue-100 text-blue-600" },
        { label: "Data Sources", value: workspace.dataSources.length, icon: Database, color: "bg-green-100 text-green-600" },
        { label: "Templates", value: workspace.templates.length, icon: MessageSquare, color: "bg-purple-100 text-purple-600" },
    ];

    return (
        <div className="p-8">
            <h1 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h1>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                {stats.map((stat) => (
                    <div key={stat.label} className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center">
                        <div className={`w-12 h-12 rounded-lg ${stat.color} flex items-center justify-center mr-4`}>
                            <stat.icon className="w-6 h-6" />
                        </div>
                        <div>
                            <p className="text-sm text-gray-500 font-medium">{stat.label}</p>
                            <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                        </div>
                    </div>
                ))}
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
                    <h2 className="text-lg font-semibold mb-4 flex items-center">
                        <Clock className="w-5 h-5 mr-2 text-gray-400" />
                        Recent Activity
                    </h2>
                    <div className="text-center py-8 text-gray-500 text-sm">
                        No recent activity to show.
                    </div>
                </div>

                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
                    <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
                    <div className="space-y-3">
                        <a href={`/workspace/${id}/query`} className="block w-full p-3 text-left border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                            <span className="font-medium text-gray-700">Start a new chat</span>
                            <p className="text-xs text-gray-500">Ask questions about your documents</p>
                        </a>
                        <a href={`/workspace/${id}/data`} className="block w-full p-3 text-left border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                            <span className="font-medium text-gray-700">Connect Data Source</span>
                            <p className="text-xs text-gray-500">Add files or connect to external drives</p>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    );
}
