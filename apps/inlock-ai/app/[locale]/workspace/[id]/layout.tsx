import Link from "next/link";
import { redirect } from "next/navigation";
import { getWorkspace } from "@/src/lib/workspace";
import { getSessionFromRequest } from "@/src/lib/auth"; // We'll use the cookie trick again or refactor
import {
    LayoutDashboard,
    MessageSquare,
    Database,
    Settings,
    LogOut,
    FileText
} from "lucide-react";

export default async function WorkspaceLayout({
    children,
    params,
}: {
    children: React.ReactNode;
    params: Promise<{ id: string }>;
}) {
    const { id } = await params;

    // Auth check (similar to page.tsx, ideally refactored)
    const { cookies } = await import("next/headers");
    const cookieStore = await cookies();
    const token = cookieStore.get("session_token")?.value;
    const { prisma } = await import("@/src/lib/db");

    if (!token) redirect("/login");

    const session = await prisma.session.findUnique({
        where: { token },
        include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) redirect("/login");

    const workspace = await getWorkspace(id, session.user.id);

    if (!workspace) {
        redirect("/workspace"); // Or 404
    }

    const navItems = [
        { name: "Dashboard", href: `/workspace/${id}`, icon: LayoutDashboard },
        { name: "Query & Draft", href: `/workspace/${id}/query`, icon: MessageSquare },
        { name: "Data Sources", href: `/workspace/${id}/data`, icon: Database },
        // { name: "Templates", href: `/workspace/${id}/templates`, icon: FileText }, // Future
    ];

    if (session.user.role === "admin") {
        navItems.push({ name: "Settings", href: `/workspace/${id}/settings`, icon: Settings });
    }

    return (
        <div className="flex h-screen bg-gray-100">
            {/* Sidebar */}
            <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
                <div className="p-6 border-b border-gray-100">
                    <h1 className="text-xl font-bold text-gray-800 truncate" title={workspace.name}>
                        {workspace.name}
                    </h1>
                    <p className="text-xs text-gray-500 mt-1">Inlock v0.1</p>
                </div>

                <nav className="flex-1 p-4 space-y-1">
                    {navItems.map((item) => (
                        <Link
                            key={item.name}
                            href={item.href}
                            className="flex items-center px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors group"
                        >
                            <item.icon className="w-5 h-5 mr-3 text-gray-400 group-hover:text-blue-600" />
                            <span className="font-medium">{item.name}</span>
                        </Link>
                    ))}
                </nav>

                <div className="p-4 border-t border-gray-100">
                    <div className="flex items-center px-4 py-3 mb-2">
                        <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold mr-3">
                            {session.user.name?.[0] || "U"}
                        </div>
                        <div className="overflow-hidden">
                            <p className="text-sm font-medium text-gray-900 truncate">{session.user.name}</p>
                            <p className="text-xs text-gray-500 truncate">{session.user.email}</p>
                        </div>
                    </div>
                    <Link
                        href="/api/auth/logout" // Assuming logout endpoint exists or we implement it
                        className="flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    >
                        <LogOut className="w-4 h-4 mr-2" />
                        Sign Out
                    </Link>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 overflow-auto">
                {children}
            </main>
        </div>
    );
}
