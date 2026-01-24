"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowRight, CheckCircle2 } from "lucide-react";
import { useTranslations } from "next-intl";

export default function ContactForm() {
    const t = useTranslations("Consulting.Contact");
    const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
    const [errorMessage, setErrorMessage] = useState("");

    const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setStatus("loading");
        setErrorMessage("");

        const form = e.currentTarget;
        const formData = new FormData(form);

        try {
            const res = await fetch("/api/contact", {
                method: "POST",
                body: formData,
            });
            const data = await res.json().catch(() => ({}));

            if (!res.ok) {
                setStatus("error");
                setErrorMessage(data?.error ?? t("errorGeneric"));
                return;
            }

            setStatus("success");
            form.reset();
        } catch (error) {
            setStatus("error");
            setErrorMessage(t("errorGeneric"));
        }
    };

    return (
        <div className="w-full max-w-xl mx-auto">
            <div className="relative group perspective-1000">
                {/* Glassmorphism Card */}
                <div className="
                    relative overflow-hidden
                    rounded-3xl border border-white/10 
                    bg-white/5 backdrop-blur-3xl 
                    shadow-2xl shadow-black/5
                    transition-all duration-500 ease-out
                    hover:shadow-3xl hover:bg-white/10
                ">
                    <div className="p-8 md:p-10 space-y-8">
                        {status === "success" ? (
                            <div className="flex flex-col items-center justify-center py-12 space-y-4 text-center animate-in fade-in zoom-in duration-500">
                                <div className="p-4 rounded-full bg-emerald-500/10 text-emerald-500">
                                    <CheckCircle2 className="w-12 h-12" />
                                </div>
                                <h3 className="text-2xl font-semibold tracking-tight text-foreground">{t("successTitle")}</h3>
                                <p className="text-muted-foreground max-w-xs">
                                    {t("successMessage")}
                                </p>
                                <Button
                                    variant="outline"
                                    onClick={() => setStatus("idle")}
                                    className="mt-4 rounded-full px-8 border-white/10 hover:bg-white/5"
                                >
                                    {t("sendAnother")}
                                </Button>
                            </div>
                        ) : (
                            <>
                                <div className="space-y-2">
                                    <h2 className="text-3xl font-semibold tracking-tight text-foreground">{t("title")}</h2>
                                    <p className="text-muted-foreground text-sm">
                                        {t("subtitle")}
                                    </p>
                                </div>

                                <form onSubmit={handleSubmit} className="space-y-6">
                                    <div className="space-y-4">
                                        <div className="space-y-2">
                                            <Input
                                                name="name"
                                                placeholder={t("name")}
                                                required
                                                className="
                                                    h-12 rounded-xl bg-white/5 border-white/10 px-4
                                                    text-foreground placeholder:text-muted-foreground/50
                                                    focus:bg-white/10 focus:border-primary/50 focus:ring-0
                                                    transition-all duration-300
                                                "
                                            />
                                        </div>
                                        <div className="space-y-2">
                                            <Input
                                                name="email"
                                                type="email"
                                                placeholder={t("email")}
                                                required
                                                className="
                                                    h-12 rounded-xl bg-white/5 border-white/10 px-4
                                                    text-foreground placeholder:text-muted-foreground/50
                                                    focus:bg-white/10 focus:border-primary/50 focus:ring-0
                                                    transition-all duration-300
                                                "
                                            />
                                        </div>
                                        <div className="space-y-2">
                                            <Input
                                                name="company"
                                                placeholder={t("company")}
                                                className="
                                                    h-12 rounded-xl bg-white/5 border-white/10 px-4
                                                    text-foreground placeholder:text-muted-foreground/50
                                                    focus:bg-white/10 focus:border-primary/50 focus:ring-0
                                                    transition-all duration-300
                                                "
                                            />
                                        </div>
                                        <div className="space-y-2">
                                            <Textarea
                                                name="message"
                                                placeholder={t("message")}
                                                required
                                                rows={5}
                                                className="
                                                    resize-none rounded-xl bg-white/5 border-white/10 p-4
                                                    text-foreground placeholder:text-muted-foreground/50
                                                    focus:bg-white/10 focus:border-primary/50 focus:ring-0
                                                    transition-all duration-300
                                                "
                                            />
                                        </div>
                                    </div>

                                    {status === "error" && (
                                        <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-sm animate-in fade-in slide-in-from-top-1">
                                            {errorMessage}
                                        </div>
                                    )}

                                    <Button
                                        type="submit"
                                        disabled={status === "loading"}
                                        className="
                                            w-full h-12 rounded-full text-base font-medium
                                            bg-primary text-primary-foreground
                                            hover:bg-primary/90 hover:scale-[1.02] active:scale-[0.98]
                                            transition-all duration-300 shadow-lg shadow-primary/25
                                        "
                                    >
                                        {status === "loading" ? (
                                            <Loader2 className="w-5 h-5 animate-spin mr-2" />
                                        ) : (
                                            <span className="flex items-center justify-center">
                                                {t("submit")} <ArrowRight className="w-4 h-4 ml-2" />
                                            </span>
                                        )}
                                    </Button>
                                </form>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
