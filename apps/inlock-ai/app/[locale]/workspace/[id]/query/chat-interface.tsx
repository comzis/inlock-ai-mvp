"use client";

import { useState, useRef, useEffect } from "react";
import { ChatMessage } from "@/components/chat/ChatMessage";
import { Send, Paperclip } from "lucide-react";

interface Message {
    role: "user" | "assistant";
    content: string;
    citations?: any[];
}

interface ChatInterfaceProps {
    workspaceId: string;
    templates: any[];
}

export default function ChatInterface({ workspaceId, templates }: ChatInterfaceProps) {
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [selectedTemplate, setSelectedTemplate] = useState<string>("");
    const messagesEndRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!input.trim() || isLoading) return;

        const userMessage = { role: "user" as const, content: input };
        setMessages((prev) => [...prev, userMessage]);
        setInput("");
        setIsLoading(true);

        try {
            const response = await fetch("/api/query", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    workspaceId,
                    query: userMessage.content,
                    templateId: selectedTemplate || undefined,
                }),
            });

            if (!response.ok) throw new Error("Failed to send message");

            const reader = response.body?.getReader();
            if (!reader) throw new Error("No reader");

            const decoder = new TextDecoder();
            let assistantMessage: Message = { role: "assistant", content: "", citations: [] };

            // Add empty assistant message to start streaming into
            setMessages((prev) => [...prev, assistantMessage]);

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value);
                const lines = chunk.split("\n\n");

                for (const line of lines) {
                    if (line.startsWith("event: citations")) {
                        const data = line.split("data: ")[1];
                        if (data) {
                            try {
                                assistantMessage.citations = JSON.parse(data);
                            } catch (e) {
                                console.error("Failed to parse citations", e);
                            }
                        }
                    } else if (line.startsWith("event: token")) {
                        const data = line.split("data: ")[1];
                        if (data) {
                            try {
                                const token = JSON.parse(data);
                                assistantMessage.content += token;
                                // Update the last message
                                setMessages((prev) => {
                                    const newMessages = [...prev];
                                    newMessages[newMessages.length - 1] = { ...assistantMessage };
                                    return newMessages;
                                });
                            } catch (e) {
                                console.error("Failed to parse token", e);
                            }
                        }
                    } else if (line.startsWith("event: done")) {
                        // Done
                    }
                }
            }
        } catch (error) {
            console.error(error);
            setMessages((prev) => [
                ...prev,
                { role: "assistant", content: "Sorry, an error occurred." },
            ]);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex flex-col h-full bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            {/* Header / Template Selector */}
            <div className="p-4 border-b border-gray-100 flex items-center justify-between bg-gray-50">
                <div className="flex items-center space-x-2">
                    <span className="text-sm font-medium text-gray-700">Template:</span>
                    <select
                        value={selectedTemplate}
                        onChange={(e) => setSelectedTemplate(e.target.value)}
                        className="text-sm border-gray-300 rounded-md shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    >
                        <option value="">Default (General Q&A)</option>
                        {templates.map((t) => (
                            <option key={t.id} value={t.id}>
                                {t.name}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-6 space-y-6">
                {messages.length === 0 && (
                    <div className="text-center text-gray-500 mt-10">
                        <p className="text-lg font-medium">Welcome to Inlock AI</p>
                        <p className="text-sm">Select a template and ask a question to get started.</p>
                    </div>
                )}
                {messages.map((m, i) => (
                    <ChatMessage
                        key={i}
                        role={m.role}
                        content={m.content}
                        citations={m.citations}
                    />
                ))}
                {isLoading && messages[messages.length - 1]?.role === "user" && (
                    <div className="flex justify-start mb-6">
                        <div className="bg-surface border border-border/50 rounded-2xl px-4 py-3">
                            <span className="animate-pulse">Thinking...</span>
                        </div>
                    </div>
                )}
                <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className="p-4 border-t border-gray-100 bg-white">
                <form onSubmit={handleSubmit} className="flex gap-2">
                    <button
                        type="button"
                        className="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
                        title="Attach file (coming soon)"
                    >
                        <Paperclip className="w-5 h-5" />
                    </button>
                    <input
                        type="text"
                        value={input}
                        onChange={(e) => setInput(e.target.value)}
                        placeholder="Ask a question..."
                        className="flex-1 border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        disabled={isLoading}
                    />
                    <button
                        type="submit"
                        disabled={isLoading || !input.trim()}
                        className="p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        <Send className="w-5 h-5" />
                    </button>
                </form>
            </div>
        </div>
    );
}
