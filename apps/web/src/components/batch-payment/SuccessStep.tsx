import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ExternalLink } from "lucide-react";

interface SuccessStepProps {
  selectedToken: string;
  recipientCount: number;
  totalAmount: number;
  txHash: string | null;
  onDownloadCSV: () => void;
  onNewBatch: () => void;
}

export function SuccessStep({
  selectedToken,
  recipientCount,
  totalAmount,
  txHash,
  onDownloadCSV,
  onNewBatch,
}: SuccessStepProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>✅ Batch Transfer Complete!</CardTitle>
        <CardDescription>Your batch payment has been successfully processed</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="p-4 rounded-lg bg-gradient-to-br from-success/10 to-accent/10 border border-success/20">
          <div className="text-sm text-muted-foreground mb-2">Summary</div>
          <div className="flex justify-between text-sm">
            <span>Total Recipients</span>
            <span className="font-medium">{recipientCount}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span>Total Amount</span>
            <span className="font-medium">
              {totalAmount.toFixed(6)} {selectedToken}
            </span>
          </div>
          {txHash && (
            <div className="mt-3 pt-3 border-t border-success/20">
              <a
                href={`https://celo-sepolia.blockscout.com/tx/${txHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 text-sm text-primary hover:underline"
              >
                View on Sepolia Explorer
                <ExternalLink className="h-3 w-3" />
              </a>
            </div>
          )}
        </div>

        <div className="flex gap-2">
          <Button variant="outline" className="flex-1" onClick={onDownloadCSV}>
            Export CSV
          </Button>
          <Button className="flex-1" variant="outline" onClick={onNewBatch}>
            New Batch
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
