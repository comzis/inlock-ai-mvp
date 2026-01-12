"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

export default function ContactForm() {
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);
    const [loading, setLoading] = useState(false);

    return (
        <Card variant="elevated" className="max-w-2xl mx-auto">
            <form
                className="space-y-6"
                onSubmit={async (e) => {
                    e.preventDefault();
                    setError(null);
                    setSuccess(false);
                    setLoading(true);
                    const form = e.currentTarget;
                    const formData = new FormData(form);
                    try {
                        const res = await fetch("/api/contact", {
                            method: "POST",
                            body: formData,
                        });
                        const data = await res.json().catch(() => null);
                        if (!res.ok) {
                            setError(data?.error ?? "Submission failed");
                            return;
                        }
                        setSuccess(true);
                        form.reset();
                    } finally {
                        setLoading(false);
                    }
                }}
            >
                {error && (
                    <div className="rounded-xl bg-red-950/40 border border-red-700/50 p-4">
                        <p className="text-sm text-red-400">{error}</p>
                    </div>
                )}
                {success && (
                    <div className="rounded-xl bg-emerald-950/40 border border-emerald-700/50 p-4">
                        <p className="text-sm text-emerald-300">
                            Thank you for your message! We&apos;ll get back to you soon.
                        </p>
                    </div>
                )}
                <div className="space-y-2">
                    <label className="block text-sm font-medium" htmlFor="name">
                        Name
                    </label>
                    <Input id="name" name="name" required placeholder="Your name" />
                </div>
                <div className="space-y-2">
                    <label className="block text-sm font-medium" htmlFor="email">
                        Email
                    </label>
                    <Input
                        id="email"
                        name="email"
                        type="email"
                        required
                        placeholder="your.email@example.com"
                    />
                </div>
                <div className="space-y-2">
                    <label className="block text-sm font-medium" htmlFor="company">
                        Company
                    </label>
                    <Input
                        id="company"
                        name="company"
                        placeholder="Your company name"
                    />
                </div>
                <div className="space-y-2">
                    <label className="block text-sm font-medium" htmlFor="message">
                        Message
                    </label>
                    <Textarea
                        id="message"
                        name="message"
                        rows={6}
                        required
                        placeholder="Tell us about your AI transformation goals..."
                    />
                </div>
                <Button type="submit" size="lg" className="w-full" disabled={loading}>
                    {loading ? "Sending..." : "Submit"}
                </Button>
            </form>
        </Card>
    );
}
