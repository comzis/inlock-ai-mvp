import Image from "next/image";
import Link from "next/link";

interface LogoProps {
  width?: number;
  height?: number;
  priority?: boolean;
  className?: string;
  href?: string;
}

// Logo is 724x173, aspect ratio ~4.18:1
export function Logo({ 
  width = 145, 
  height = 35, 
  priority = false,
  className = "",
  href = "/"
}: LogoProps) {
  const logoImage = (
    <Image
      src="/branding/logo_inLock-01.png"
      alt="Inlock"
      width={width}
      height={height}
      priority={priority}
      className={`hover:opacity-80 transition-opacity ${className}`}
    />
  );

  if (href) {
    return (
      <Link href={href} className="inline-block">
        {logoImage}
      </Link>
    );
  }

  return logoImage;
}

