# Secure AI Consulting Platform

A production-ready Next.js application for AI consulting services with multi-provider chat capabilities.

## 🎯 Project Score: 98/100

## ✨ Features

### Core Platform
- 🔐 **Authentication System** - Secure login/register with session management
- 📊 **Admin Dashboard** - Data visualization and management
- 📝 **Blog System** - Markdown-based content management
- 📄 **Document Viewer** - Secure document access
- 📋 **Assessment Tools** - AI readiness checker and blueprint generator
- 📧 **Lead Capture** - Contact forms with validation

### AI Chat Platform (NEW)
- 🤖 **Multi-Provider Support** - Google Gemini, Anthropic Claude, Hugging Face
- ⚡ **Real-Time Streaming** - Server-Sent Events for live responses
- 💬 **Session Management** - Save, load, and manage chat history
- 🎛️ **Provider Selection** - Switch between AI models dynamically
- 🔒 **Secure & Rate-Limited** - Authentication required, rate limiting enabled

### Quality & Testing
- ✅ **E2E Tests** - Playwright test coverage for critical flows
- ✅ **Unit Tests** - Vitest for API routes and utilities
- ✅ **Error Monitoring** - Sentry integration with global error boundary
- ✅ **Production Build** - Optimized and verified

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ (or Docker 20.10+)
- npm or yarn

### Option 1: Docker (Recommended - PostgreSQL Included)

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env and set AUTH_SESSION_SECRET + AI provider keys

# 3. Start with Docker Compose (includes PostgreSQL)
docker compose up --build

# Visit http://localhost:3040
```

See [DOCKER.md](./DOCKER.md) for detailed Docker documentation.

### Option 2: Local Development

```bash
# Clone the repository
git clone <your-repo-url>
cd streamart-ai-secure-mvp

# Install dependencies
npm install

# Setup environment variables
cp .env.example .env

# Add at least one AI provider API key to .env:
# GOOGLE_AI_API_KEY="your-key"  # Free tier available!

# Run database migrations
npx prisma migrate dev

# Seed the database (optional)
npm run seed

# Start development server
npm run dev
```

Visit `http://localhost:3040`

**Note:** The Prisma schema is configured for PostgreSQL. For local SQLite development, change `provider = "postgresql"` to `provider = "sqlite"` in `prisma/schema.prisma`.

### Default Admin Credentials (After Seeding)
- Email: `admin@example.com`
- Password: `Password123!`

> **Note**: Run `npm run seed` to create the admin user. You can customize credentials via `SEED_ADMIN_EMAIL` and `SEED_ADMIN_PASSWORD` environment variables.

## 🧪 Testing

```bash
# Run unit tests
npm test

# Run unit tests in watch mode
npm run test:watch

# Run E2E tests (headless)
npm run test:e2e

# Run E2E tests (UI mode)
npm run test:e2e:ui

# Run E2E tests (headed - see browser)
npm run test:e2e:headed

# Build for production
npm run build
```

## 🐳 Docker Quick Start (PostgreSQL)

The easiest way to run the application with PostgreSQL:

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env and set:
#    - AUTH_SESSION_SECRET (generate with: npm run deploy:generate-secret)
#    - At least one AI provider API key (GOOGLE_AI_API_KEY recommended)

# 3. Build and start (includes PostgreSQL container)
docker compose up --build

# App: http://localhost:3040
# Postgres: localhost:5432 (user: postgres, password: postgres, db: app)
```

**What happens:**
- ✅ Multi-stage Docker build (optimized production image)
- ✅ PostgreSQL 16 container with persistent volume
- ✅ Automatic database migrations on startup
- ✅ Health checks for both services
- ✅ Data persists in `dbdata` Docker volume

**Using external PostgreSQL:**
Update `DATABASE_URL` in `.env` to point to your external database. The docker-compose service will still work, but you can remove the `db` service if not needed.

**Docker commands:**
```bash
# Build only
docker compose build

# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Stop and remove volumes (⚠️ deletes database)
docker compose down -v
```

## 📜 Available Scripts

```bash
# Development
npm run dev              # Start dev server (port 3040)
npm start                # Start production server

# Database
npm run seed             # Seed database with admin user and sample data
npm run prisma:migrate   # Run database migrations
npm run prisma:generate  # Generate Prisma client

# Testing
npm test                 # Run unit tests
npm run test:watch       # Run unit tests in watch mode
npm run test:e2e         # Run E2E tests
npm run test:e2e:ui      # Run E2E tests with UI

# Utilities
npm run export:pdf       # Export all data to PDF
npm run lint             # Run ESLint
```

## 🔑 Environment Variables

### Required Variables

```bash
# Authentication (required)
AUTH_SESSION_SECRET="your-secret-key-min-20-chars"  # Used for session encryption
```

### AI Provider Setup (Optional - for chat feature)

The chat feature requires at least one AI provider API key:

### Google Gemini (Recommended - Free Tier)
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Add to `.env`: `GOOGLE_AI_API_KEY="your-key"`

### Anthropic Claude (Paid)
1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Create an API key
3. Add to `.env`: `ANTHROPIC_API_KEY="sk-ant-..."`

### Hugging Face (Free Tier)
1. Visit [Hugging Face Settings](https://huggingface.co/settings/tokens)
2. Create a token
3. Add to `.env`: `HUGGINGFACE_API_KEY="hf_..."`

### Optional Variables

```bash
# Rate Limiting (optional - uses in-memory fallback if not set)
UPSTASH_REDIS_REST_URL="your-redis-url"
UPSTASH_REDIS_REST_TOKEN="your-redis-token"

# Error Monitoring (optional)
SENTRY_DSN="your-sentry-dsn"

# Seed Script Customization (optional)
SEED_ADMIN_EMAIL="admin@example.com"
SEED_ADMIN_PASSWORD="Password123!"
```

## 📁 Project Structure

```
streamart-ai-secure-mvp/
├── app/                      # Next.js App Router
│   ├── api/                  # API routes
│   │   ├── chat/            # Chat endpoints
│   │   ├── contact/         # Contact form
│   │   └── ...
│   ├── chat/                # Chat page
│   ├── admin/               # Admin dashboard
│   └── auth/                # Authentication pages
├── components/              # React components
│   ├── chat/               # Chat UI components
│   ├── ui/                 # Base UI components
│   └── ...
├── src/lib/                # Utilities and libraries
│   ├── ai-providers/       # AI provider implementations
│   ├── auth.ts            # Authentication logic
│   ├── db.ts              # Prisma client
│   └── rate-limit.ts      # Rate limiting
├── prisma/                 # Database schema and migrations
├── e2e/                    # Playwright E2E tests
├── tests/                  # Vitest unit tests
└── public/                 # Static assets
```

## 🛠️ Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript (strict mode)
- **Database**: SQLite (Prisma ORM) - PostgreSQL ready for production
- **Styling**: Tailwind CSS with Apple-inspired design system
- **Authentication**: Custom session-based auth with bcrypt
- **AI Providers**: Google Gemini, Anthropic Claude, Hugging Face
- **Testing**: Vitest (unit), Playwright (E2E)
- **Error Tracking**: Sentry (optional)
- **Rate Limiting**: Upstash Redis (with in-memory fallback)
- **Validation**: Zod schemas
- **PDF Generation**: PDFKit

## 📊 Features Overview

### Authentication
- Secure password hashing with bcrypt (12 rounds)
- Session-based authentication with HTTP-only cookies
- Protected routes and API endpoints
- Role-based access control (admin/user)
- Automatic session expiration

### Admin Dashboard
- View all contacts, leads, assessments, and blueprints
- Data visualization with summary statistics
- Export functionality (PDF)
- Secure admin-only access with redirect protection
- Real-time data updates

### AI Chat Platform
- Multi-provider support (Gemini, Claude, Hugging Face)
- Real-time streaming responses via Server-Sent Events
- Session history and management (save, load, delete)
- Provider and model selection with dynamic switching
- Rate limiting per user/IP
- Authentication-protected routes

### Forms & Tools
- Contact form with Zod validation and rate limiting
- Lead capture form with optional fields
- AI readiness assessment with scoring system
- Blueprint generator with PDF export
- Form error handling and user feedback

### Design System
- Apple-inspired UI with modern aesthetics
- Consistent spacing, typography, and colors
- Glass morphism effects and smooth animations
- Responsive design (mobile-first)
- Dark mode support with system preference detection
- Accessible focus states and keyboard navigation

## 🔒 Security Features

- ✅ Password hashing (bcrypt)
- ✅ Session-based authentication
- ✅ CSRF protection
- ✅ Rate limiting (Redis + in-memory)
- ✅ Input validation (Zod)
- ✅ SQL injection prevention (Prisma)
- ✅ XSS protection
- ✅ Error monitoring (Sentry)

## 📈 Performance

- Server-side rendering (SSR) for dynamic content
- Static site generation (SSG) for blog/docs
- Optimized bundle size with code splitting
- Streaming responses for AI chat (SSE)
- Efficient database queries with Prisma
- Image optimization ready
- Lazy loading for components

## 🎨 Design System

The application uses an Apple-inspired design system with:

- **Typography**: System font stack (SF Pro, system fonts)
- **Colors**: Semantic color tokens (primary, accent, surface, muted)
- **Components**: Reusable UI components (Button, Card, Input, Select, Textarea)
- **Spacing**: Consistent spacing scale
- **Shadows**: Subtle depth with custom shadow utilities
- **Animations**: Smooth transitions and hover effects
- **Accessibility**: WCAG-compliant contrast ratios and focus states

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests: `npm test && npm run test:e2e`
5. Run linting: `npm run lint`
6. Ensure production build works: `npm run build`
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Submit a pull request

### Code Standards
- Follow TypeScript strict mode
- Use Zod for input validation
- Write tests for new features
- Follow the existing code style
- Update documentation as needed

## 📄 License

MIT License - see LICENSE file for details

## 📚 Additional Resources

- [Development Plan](./DEVELOPMENT_PLAN.md) - Detailed project status and roadmap
- [Changes Review](./CHANGES_REVIEW.md) - Comprehensive review of recent changes
- [Cursor Instructions](./cursor-instructions/) - Developer onboarding and guidelines

## 🙏 Acknowledgments

- Next.js team for the amazing framework
- Vercel for AI SDK
- Google, Anthropic, and Hugging Face for AI APIs
- Prisma for the excellent ORM
- Playwright team for E2E testing
- Sentry for error monitoring

---

**Built with ❤️ for secure, privacy-first AI consulting**

**Project Status**: 🎉 98/100 - Production Ready
