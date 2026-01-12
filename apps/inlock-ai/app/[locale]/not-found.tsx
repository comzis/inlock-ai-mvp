import Link from 'next/link';

export default function NotFound() {
    return (
        <div className="min-h-screen flex items-center justify-center px-6">
            <div className="max-w-md w-full space-y-6 text-center">
                <h1 className="text-6xl font-bold">404</h1>
                <h2 className="text-2xl font-semibold">Page Not Found</h2>
                <p className="text-muted">
                    The page you&apos;re looking for doesn&apos;t exist.
                </p>
                <Link
                    href="/"
                    className="inline-flex items-center justify-center rounded-xl px-6 h-11 bg-primary text-primary-foreground hover:bg-primary/90 transition-colors"
                >
                    Go Home
                </Link>
            </div>
        </div>
    );
}
