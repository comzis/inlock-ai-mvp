import NextAuth from "next-auth";
import Auth0Provider from "next-auth/providers/auth0";

/**
 * NextAuth.js configuration with Auth0 provider
 * 
 * Setup:
 * 1. Create Auth0 application (Single Page App) at https://manage.auth0.com
 * 2. Set Callback URLs: https://inlock.ai/api/auth/callback/auth0
 * 3. Set Logout URLs: https://inlock.ai
 * 4. Add environment variables to .env.production:
 *    - AUTH0_WEB_CLIENT_ID
 *    - AUTH0_WEB_CLIENT_SECRET
 *    - AUTH0_ISSUER (e.g., https://your-tenant.auth0.com)
 *    - NEXTAUTH_SECRET (generate with: openssl rand -base64 32)
 *    - NEXTAUTH_URL=https://inlock.ai
 */

const handler = NextAuth({
  providers: [
    Auth0Provider({
      clientId: process.env.AUTH0_WEB_CLIENT_ID!,
      clientSecret: process.env.AUTH0_WEB_CLIENT_SECRET!,
      issuer: process.env.AUTH0_ISSUER,
      authorization: {
        params: {
          scope: "openid profile email",
          // Include roles in token if configured in Auth0
          audience: process.env.AUTH0_AUDIENCE || undefined,
        },
      },
    }),
  ],
  callbacks: {
    async jwt({ token, account, profile }) {
      // Persist the OAuth access_token and user profile to the token right after signin
      if (account && profile) {
        token.auth0Id = profile.sub;
        token.accessToken = account.access_token;
        
        // Extract roles from Auth0 custom claim (if configured)
        // Auth0 rule/action should add: context.idToken["https://inlock.ai/roles"] = user.app_metadata.roles
        token.roles = (profile as any)["https://inlock.ai/roles"] || [];
      }
      return token;
    },
    async session({ session, token }) {
      // Send properties to the client
      if (session.user) {
        (session.user as any).id = token.auth0Id as string;
        (session.user as any).roles = token.roles || [];
      }
      return session;
    },
  },
  pages: {
    signIn: "/auth/signin",
    error: "/auth/error",
  },
  secret: process.env.NEXTAUTH_SECRET,
});

export { handler as GET, handler as POST };

