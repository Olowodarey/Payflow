"use client";

import React, { useState, useEffect } from "react";
import { useAccount, useBalance } from "wagmi";
import { useBatchTransfer, useContractPaused } from "@/hooks/useBatchTransfer";
import { useTokenApproval, useTokenAllowance, useTokenBalance } from "@/hooks/useTokenApproval";
import { TOKEN_ADDRESSES } from "@/lib/contracts/batchTransfer";
import { Address, formatUnits, parseUnits } from "viem";
import { defineChain } from "viem";
import { UploadRecipient } from "@/components/batch-payment/UploadRecipients";
import { NetworkWarning } from "@/components/batch-payment/NetworkWarning";
import { ProgressIndicator } from "@/components/batch-payment/ProgressIndicator";
import { RecipientForm } from "@/components/batch-payment/RecipientForm";
import { ReviewStep } from "@/components/batch-payment/ReviewStep";
import { SuccessStep } from "@/components/batch-payment/SuccessStep";

// Define Celo Sepolia chain
const celoSepolia = defineChain({
  id: 11142220,
  name: "Celo Sepolia",
  nativeCurrency: { decimals: 18, name: "CELO", symbol: "CELO" },
  rpcUrls: { default: { http: ["https://forno.celo-sepolia.celo-testnet.org"] } },
  blockExplorers: { default: { name: "Celo Sepolia Blockscout", url: "https://celo-sepolia.blockscout.com" } },
  testnet: true,
});

// Token configuration
const TOKENS = {
  CELO: { symbol: "CELO", name: "Celo", icon: "🟡", address: TOKEN_ADDRESSES.CELO, decimals: 18 },
  cUSD: { symbol: "cUSD", name: "Celo Dollar", icon: "💵", address: TOKEN_ADDRESSES.cUSD, decimals: 18 },
  USDC: { symbol: "USDC", name: "USD Coin", icon: "💰", address: TOKEN_ADDRESSES.USDC, decimals: 6 },
  cEUR: { symbol: "cEUR", name: "Celo Euro", icon: "💶", address: TOKEN_ADDRESSES.cEUR, decimals: 18 },
} as const;
type TokenSymbol = keyof typeof TOKENS;
type Recipient = { id: string; address: string; amount: string };

export default function BatchPaymentPage() {
  const [step, setStep] = useState(1);
  const [selectedToken, setSelectedToken] = useState<TokenSymbol>("CELO");
  const [recipients, setRecipients] = useState<Recipient[]>([{ id: "1", address: "", amount: "" }]);
  const [showUpload, setShowUpload] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [notice, setNotice] = useState<{ type: "success" | "error" | "info"; message: string } | null>(null);

  // Wagmi hooks
  const { address, isConnected, chain } = useAccount();
  const { isPaused } = useContractPaused();
  const selectedTokenConfig = TOKENS[selectedToken];
  const isNativeCELO = selectedTokenConfig.address === TOKEN_ADDRESSES.CELO;

  // Balance hooks
  const { data: nativeBalance } = useBalance({ address });
  const { balance: tokenBalance, refetch: refetchTokenBalance } = useTokenBalance(
    selectedTokenConfig.address,
    address
  );

  // Contract interaction hooks
  const { executeBatchTransfer, hash, isPending, isConfirming, isConfirmed, error } = useBatchTransfer();
  const {
    approve,
    isPending: isApproving,
    isConfirming: isApprovingConfirming,
    isConfirmed: isApproved,
  } = useTokenApproval(selectedTokenConfig.address);
  const { allowance, refetch: refetchAllowance } = useTokenAllowance(selectedTokenConfig.address, address);

  const notify = ({ description, variant }: { description: string; variant?: "destructive" }) => {
    setNotice({ type: variant === "destructive" ? "error" : "success", message: description });
    setTimeout(() => setNotice(null), 2500);
  };

  // Recipient management
  const addRecipient = () => {
    const newId = (Math.max(...recipients.map((r) => parseInt(r.id)), 0) + 1).toString();
    setRecipients([...recipients, { id: newId, address: "", amount: "" }]);
  };

  const removeRecipient = (id: string) => {
    if (recipients.length > 1) setRecipients(recipients.filter((r) => r.id !== id));
  };

  const updateRecipient = (id: string, field: keyof Recipient, value: string) => {
    setRecipients(recipients.map((r) => (r.id === id ? { ...r, [field]: value } : r)));
  };

  const totalAmount = () => recipients.reduce((sum, r) => sum + (parseFloat(r.amount) || 0), 0);

  const handleImported = (rows: UploadRecipient[]) => {
    const mapped: Recipient[] = rows.map((r, idx) => ({ id: String(idx + 1), address: r.address, amount: r.amount }));
    setRecipients(mapped);
    setShowUpload(false);
    notify({ description: `Imported ${mapped.length} recipients.` });
  };

  const validateForm = () => {
    if (recipients.some((r) => !r.address.trim() || !r.amount.trim())) {
      notify({ description: "Please fill in every recipient address and amount.", variant: "destructive" });
      return false;
    }
    if (recipients.some((r) => (parseFloat(r.amount) || 0) <= 0)) {
      notify({ description: "All amounts must be greater than 0.", variant: "destructive" });
      return false;
    }
    if (recipients.some((r) => r.address.length < 6)) {
      notify({ description: "One or more wallet addresses look invalid.", variant: "destructive" });
      return false;
    }
    return true;
  };

  const needsApproval = () => {
    if (isNativeCELO) return false;
    const total = totalAmount();
    const totalInWei = parseUnits(total.toString(), selectedTokenConfig.decimals);
    return allowance < totalInWei;
  };

  const handleApprove = () => {
    const total = totalAmount();
    approve(total.toString(), selectedTokenConfig.decimals);
  };

  const handleSubmit = async () => {
    if (!address) {
      notify({ description: "Please connect your wallet", variant: "destructive" });
      return;
    }
    if (chain?.id !== celoSepolia.id) {
      notify({ description: "Please switch to Celo Sepolia Testnet", variant: "destructive" });
      return;
    }
    if (isPaused) {
      notify({ description: "Contract is currently paused", variant: "destructive" });
      return;
    }

    const total = totalAmount();
    const totalInWei = parseUnits(total.toString(), selectedTokenConfig.decimals);
    const currentBalance = isNativeCELO ? nativeBalance?.value ?? 0n : tokenBalance;

    if (currentBalance < totalInWei) {
      notify({ description: `Insufficient ${selectedToken} balance`, variant: "destructive" });
      return;
    }

    if (!isNativeCELO && needsApproval()) {
      notify({ description: "Please approve token spending first", variant: "destructive" });
      return;
    }

    try {
      const batchRecipients = recipients.map((r) => ({ address: r.address as Address, amount: r.amount }));
      executeBatchTransfer(selectedTokenConfig.address, batchRecipients, selectedTokenConfig.decimals);
    } catch (err: any) {
      notify({ description: err.message || "Failed to submit batch", variant: "destructive" });
    }
  };

  const downloadCSV = () => {
    const csv = ["Address,Amount\n", ...recipients.map((r) => `${r.address},${r.amount}\n`)].join("");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "batch-recipients.csv";
    a.click();
  };

  const handleNext = () => {
    if (step === 1) {
      if (!validateForm()) return;
      setStep(2);
    } else if (step === 2) {
      handleSubmit();
    }
  };

  const getBalance = () => {
    if (isNativeCELO) {
      return nativeBalance?.formatted ? `${parseFloat(nativeBalance.formatted).toFixed(4)} ${selectedToken}` : "Loading...";
    }
    return tokenBalance ? `${parseFloat(formatUnits(tokenBalance, selectedTokenConfig.decimals)).toFixed(4)} ${selectedToken}` : "Loading...";
  };

  // Effects
  useEffect(() => {
    if (isApproved) {
      refetchAllowance();
      notify({ description: "Token approval confirmed! You can now submit the batch." });
    }
  }, [isApproved]);

  useEffect(() => {
    if (isConfirmed && hash) {
      setTxHash(hash);
      setStep(3);
      refetchTokenBalance();
      notify({ description: "Batch transfer completed successfully!" });
    }
  }, [isConfirmed, hash]);

  useEffect(() => {
    if (error) {
      notify({ description: error.message || "Transaction failed", variant: "destructive" });
    }
  }, [error]);

  const isCorrectNetwork = chain?.id === celoSepolia.id;

  return (
    <div className="flex flex-col min-h-screen">
      <div className="flex-1 py-8 md:py-12 px-4 sm:px-6 lg:px-8">
        <div className="container mx-auto max-w-2xl">
          <NetworkWarning isConnected={isConnected} isCorrectNetwork={isCorrectNetwork} isPaused={isPaused} />

          {notice && (
            <div
              className={`mb-6 rounded-md border p-3 text-sm ${
                notice.type === "error"
                  ? "border-destructive text-destructive-foreground bg-destructive/10"
                  : "border-border bg-muted/50 text-foreground"
              }`}
            >
              {notice.message}
            </div>
          )}

          <ProgressIndicator currentStep={step} />

          {step === 1 && isConnected && isCorrectNetwork && (
            <RecipientForm
              selectedToken={selectedToken}
              recipients={recipients}
              showUpload={showUpload}
              balance={getBalance()}
              totalAmount={totalAmount()}
              onTokenChange={(token) => setSelectedToken(token as TokenSymbol)}
              onAddRecipient={addRecipient}
              onRemoveRecipient={removeRecipient}
              onUpdateRecipient={updateRecipient}
              onToggleUpload={() => setShowUpload((v) => !v)}
              onImported={handleImported}
              onNext={handleNext}
              tokens={Object.values(TOKENS)}
            />
          )}

          {step === 2 && (
            <ReviewStep
              selectedToken={selectedToken}
              recipients={recipients}
              balance={getBalance()}
              totalAmount={totalAmount()}
              needsApproval={needsApproval()}
              isApproving={isApproving}
              isApprovingConfirming={isApprovingConfirming}
              isPending={isPending}
              isConfirming={isConfirming}
              onBack={() => setStep(1)}
              onApprove={handleApprove}
              onSubmit={handleNext}
            />
          )}

          {step === 3 && (
            <SuccessStep
              selectedToken={selectedToken}
              recipientCount={recipients.length}
              totalAmount={totalAmount()}
              txHash={txHash}
              onDownloadCSV={downloadCSV}
              onNewBatch={() => {
                setStep(1);
                setRecipients([{ id: "1", address: "", amount: "" }]);
              }}
            />
          )}
        </div>
      </div>
    </div>
  );
}
