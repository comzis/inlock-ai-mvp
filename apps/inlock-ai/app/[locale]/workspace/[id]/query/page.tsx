import { getWorkspace } from "@/src/lib/workspace";
import { redirect } from "next/navigation";
import ChatInterface from "./chat-interface";

export default async function QueryPage({
    params,
}: {
    params: Promise<{ id: string }>;
}) {
    const { id } = await params;

    // Use the getCurrentUser helper for auth
    const { getCurrentUser } = await import("@/src/lib/auth");
    const user = await getCurrentUser();

    if (!user) {
        redirect("/auth/login");
    }

    const workspace = await getWorkspace(id, user.id);
    if (!workspace) redirect("/workspace");

    return (
        <div className="h-full p-4 flex flex-col">
            <h1 className="text-xl font-bold mb-4 text-gray-800">Query & Draft</h1>
            <div className="flex-1 min-h-0">
                <ChatInterface workspaceId={id} templates={workspace.templates} />
            </div>
        </div>
    );
}
