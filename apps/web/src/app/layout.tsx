import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

import { Navbar } from '@/components/navbar';
import { WalletProvider } from "@/components/wallet-provider"

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Payflow',
  description: 'PayFlow is a Celo-powered payment protocol designed to make on-chain transfers faster, cheaper, and more inclusive. With PayFlow, users can send funds to multiple wallet addresses in a single transaction—reducing gas costs, saving time, and simplifying complex payouts. But it goes further: PayFlow introduces claim-code payments, enabling users to send crypto without needing the recipient’s wallet address. Instead, a secure claim code is generated, and the receiver can redeem it at any time, even if they don’t yet have a wallet—making it perfect for giveaways, community rewards, and onboarding new Web3 users.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {/* Navbar is included on all pages */}
        <div className="relative flex min-h-screen flex-col">
          <WalletProvider>
            <Navbar />
            <main className="flex-1">
              {children}
            </main>
          </WalletProvider>
        </div>
      </body>
    </html>
  );
}
