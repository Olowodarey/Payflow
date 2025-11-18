import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Loader2 } from "lucide-react";

type Recipient = { id: string; address: string; amount: string };

interface ReviewStepProps {
  selectedToken: string;
  recipients: Recipient[];
  balance: string;
  totalAmount: number;
  needsApproval: boolean;
  isApproving: boolean;
  isApprovingConfirming: boolean;
  isPending: boolean;
  isConfirming: boolean;
  onBack: () => void;
  onApprove: () => void;
  onSubmit: () => void;
}

export function ReviewStep({
  selectedToken,
  recipients,
  balance,
  totalAmount,
  needsApproval,
  isApproving,
  isApprovingConfirming,
  isPending,
  isConfirming,
  onBack,
  onApprove,
  onSubmit,
}: ReviewStepProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Review Batch</CardTitle>
        <CardDescription>Confirm recipients and total before sending</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Recipients Table */}
        <div className="rounded-lg border border-border overflow-hidden">
          <div className="grid grid-cols-2 sm:grid-cols-3 bg-muted/50 text-xs font-medium text-muted-foreground px-3 py-2">
            <div>Address</div>
            <div>Amount</div>
            <div className="hidden sm:block">Token</div>
          </div>
          <div className="divide-y">
            {recipients.map((r) => (
              <div key={r.id} className="grid grid-cols-2 sm:grid-cols-3 px-3 py-2 text-sm">
                <div className="font-mono break-all pr-3">{r.address}</div>
                <div>
                  {r.amount} {selectedToken}
                </div>
                <div className="hidden sm:block">{selectedToken}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Summary */}
        <div className="p-3 rounded-lg bg-muted/50 space-y-1">
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Total Recipients:</span>
            <span className="font-medium">{recipients.length}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Total Amount:</span>
            <span className="font-medium">
              {totalAmount.toFixed(6)} {selectedToken}
            </span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Your Balance:</span>
            <span className="font-medium">{balance}</span>
          </div>
        </div>

        {/* Approval Section for ERC20 */}
        {needsApproval && (
          <div className="p-3 rounded-lg border border-yellow-500 bg-yellow-500/10">
            <p className="text-sm text-yellow-700 dark:text-yellow-400 mb-3">
              ⚠️ You need to approve the contract to spend your {selectedToken} tokens
            </p>
            <Button
              onClick={onApprove}
              disabled={isApproving || isApprovingConfirming}
              className="w-full"
              variant="outline"
            >
              {isApproving || isApprovingConfirming ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  {isApproving ? "Approving..." : "Confirming..."}
                </>
              ) : (
                "Approve Token Spending"
              )}
            </Button>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex gap-2">
          <Button variant="outline" className="flex-1" onClick={onBack}>
            Back
          </Button>
          <Button
            className="flex-1"
            onClick={onSubmit}
            disabled={isPending || isConfirming || needsApproval}
          >
            {isPending || isConfirming ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                {isPending ? "Submitting..." : "Confirming..."}
              </>
            ) : (
              "Confirm & Submit"
            )}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
