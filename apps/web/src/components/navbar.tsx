"use client"

import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { Menu, ExternalLink } from "lucide-react"

import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetContent,
  SheetTrigger,
} from "@/components/ui/sheet"
import { WalletConnectButton } from "@/components/connect-button"

const navLinks = [
  { name: "Home", href: "/" },
  { name: "Batch payment", href: "/batch-payment" },
  { name: "Create payment", href: "/create-payment" },
  { name: "Claim payment", href: "/claim-payment" },
]

export function Navbar() {
  const pathname = usePathname()
  
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-md supports-[backdrop-filter]:bg-background/60">
      <div className="container grid h-16 max-w-screen-2xl grid-cols-3 items-center px-4">
        <div className="flex items-center gap-2">
          {/* Mobile menu button */}
          <Sheet>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon" className="md:hidden">
                <Menu className="h-5 w-5" />
                <span className="sr-only">Toggle menu</span>
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-80">
              <div className="flex items-center gap-2 mb-8">

                <span className="font-bold text-lg">
                  Payflow
                </span>
              </div>
              <nav className="flex flex-col gap-4">
                {navLinks.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                   
                    className={`flex items-center gap-2 text-base font-medium transition-colors hover:text-primary ${
                      pathname === link.href ? "text-foreground" : "text-foreground/70"
                    }`}
                  >
                    {link.name}
                  
                  </Link>
                ))}
                <div className="mt-6 pt-6 border-t">
                  <WalletConnectButton />
                </div>
              </nav>
            </SheetContent>
          </Sheet>

          {/* Logo */}
          <Link href="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">

            <span className="hidden font-bold text-xl sm:inline-block">
              GigiPay
            </span>
          </Link>
        </div>
        
        {/* Desktop navigation (centered) */}
        <nav className="hidden md:flex items-center justify-center gap-8">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              
              className={`flex items-center gap-1.5 text-sm font-medium transition-colors hover:text-primary ${
                pathname === link.href
                  ? "text-foreground"
                  : "text-foreground/70"
              }`}
            >
              {link.name}
              
            </Link>
          ))}
        </nav>
        {/* Right actions */}
        <div className="hidden md:flex items-center justify-end gap-3">
          <WalletConnectButton />
        </div>
      </div>
    </header>
  )
}
