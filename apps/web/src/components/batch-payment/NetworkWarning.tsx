import { Card, CardContent } from "@/components/ui/card";
import { ConnectButton } from "@rainbow-me/rainbowkit";

interface NetworkWarningProps {
  isConnected: boolean;
  isCorrectNetwork: boolean;
  isPaused: boolean;
}

export function NetworkWarning({ isConnected, isCorrectNetwork, isPaused }: NetworkWarningProps) {
  return (
    <>
      {/* Wallet Connection */}
      {!isConnected && (
        <Card className="mb-6">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-4">
              <p className="text-sm text-muted-foreground">Connect your wallet to start batch payments</p>
              <ConnectButton />
            </div>
          </CardContent>
        </Card>
      )}

      {/* Wrong Network Warning */}
      {isConnected && !isCorrectNetwork && (
        <div className="mb-6 rounded-md border border-yellow-500 bg-yellow-500/10 p-3 text-sm text-yellow-700 dark:text-yellow-400">
          ⚠️ Please switch to Celo Sepolia Testnet to use batch payments
        </div>
      )}

      {/* Contract Paused Warning */}
      {isPaused && (
        <div className="mb-6 rounded-md border border-destructive bg-destructive/10 p-3 text-sm text-destructive">
          ⚠️ The batch transfer contract is currently paused
        </div>
      )}
    </>
  );
}
