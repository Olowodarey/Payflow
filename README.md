# Payflow

PayFlow is a Celo-powered payment protocol designed to make on-chain transfers faster, cheaper, and more inclusive. With PayFlow, users can send funds to multiple wallet addresses in a single transaction—reducing gas costs, saving time, and simplifying complex payouts. But it goes further: PayFlow introduces claim-code payments, enabling users to send crypto without needing the recipient’s wallet address. Instead, a secure claim code is generated, and the receiver can redeem it at any time, even if they don’t yet have a wallet—making it perfect for giveaways, community rewards, and onboarding new Web3 users.

A modern Celo blockchain application built with Next.js, TypeScript, and Turborepo.

## Getting Started

1. Install dependencies:
   ```bash
   pnpm install
   ```

2. Start the development server:
   ```bash
   pnpm dev
   ```

3. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

This is a monorepo managed by Turborepo with the following structure:

- `apps/web` - Next.js application with embedded UI components and utilities

## Available Scripts

- `pnpm dev` - Start development servers
- `pnpm build` - Build all packages and apps
- `pnpm lint` - Lint all packages and apps
- `pnpm type-check` - Run TypeScript type checking

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: shadcn/ui
- **Monorepo**: Turborepo
- **Package Manager**: PNPM

## Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [Celo Documentation](https://docs.celo.org/)
- [Turborepo Documentation](https://turbo.build/repo/docs)
- [shadcn/ui Documentation](https://ui.shadcn.com/)
