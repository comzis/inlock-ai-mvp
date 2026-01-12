import { getSessionFromRequest } from "@/src/lib/auth";
import { getUserWorkspaces } from "@/src/lib/workspace";
import { redirect } from "next/navigation";
import Link from "next/link";
import { NextRequest } from "next/server";

export default async function WorkspaceListPage() {
    // Use the getCurrentUser helper for auth
    const { getCurrentUser } = await import("@/src/lib/auth");
    const user = await getCurrentUser();

    if (!user) {
        redirect("/auth/login");
    }

    const workspaces = await getUserWorkspaces(user.id);

    if (workspaces.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center h-screen">
                <h1 className="text-2xl font-bold mb-4">No Workspaces Found</h1>
                <p className="text-gray-600">Please contact your administrator to be added to a workspace.</p>
            </div>
        );
    }

    if (workspaces.length === 1) {
        redirect(`/workspace/${workspaces[0].id}`);
    }

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center py-12">
            <h1 className="text-3xl font-bold mb-8">Select Workspace</h1>
            <div className="grid gap-6 w-full max-w-4xl px-4 md:grid-cols-2 lg:grid-cols-3">
                {workspaces.map((ws) => (
                    <Link
                        key={ws.id}
                        href={`/workspace/${ws.id}`}
                        className="block p-6 bg-white rounded-lg shadow hover:shadow-md transition-shadow border border-gray-200"
                    >
                        <h2 className="text-xl font-semibold mb-2">{ws.name}</h2>
                        <p className="text-gray-500 text-sm mb-4">{ws.description || "No description"}</p>
                        <div className="flex justify-between text-xs text-gray-400">
                            <span>{ws._count.documents} Docs</span>
                            <span>{ws._count.templates} Templates</span>
                        </div>
                    </Link>
                ))}
            </div>
        </div>
    );
}
