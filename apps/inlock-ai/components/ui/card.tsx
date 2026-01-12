import * as React from "react";
import { cn } from "@/src/lib/utils";

type CardProps = React.HTMLAttributes<HTMLDivElement> & {
  variant?: "default" | "elevated" | "glass";
  padding?: "base" | "none";
};

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant = "default", padding = "base", ...props }, ref) => (
  <div
    ref={ref}
    className={cn(
        "rounded-2xl border bg-card text-card-foreground transition-all duration-200",
        padding === "base" && "p-6 sm:p-7 lg:p-8",
        variant === "default" && "shadow-sm border-border/50",
        variant === "elevated" && "shadow-apple border-border/50",
        variant === "glass" && "glass-card",
        className
      )}
    {...props}
  />
  )
);
Card.displayName = "Card";

export { Card };
