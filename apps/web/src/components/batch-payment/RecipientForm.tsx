import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Plus, Trash2, ArrowRight } from "lucide-react";
import UploadRecipients, { UploadRecipient } from "./UploadRecipients";

type Recipient = { id: string; address: string; amount: string };

interface RecipientFormProps {
  selectedToken: string;
  recipients: Recipient[];
  showUpload: boolean;
  balance: string;
  totalAmount: number;
  onTokenChange: (token: string) => void;
  onAddRecipient: () => void;
  onRemoveRecipient: (id: string) => void;
  onUpdateRecipient: (id: string, field: "address" | "amount", value: string) => void;
  onToggleUpload: () => void;
  onImported: (rows: UploadRecipient[]) => void;
  onNext: () => void;
  tokens: Array<{ symbol: string; name: string }>;
}

const inputClass =
  "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2";

export function RecipientForm({
  selectedToken,
  recipients,
  showUpload,
  balance,
  totalAmount,
  onTokenChange,
  onAddRecipient,
  onRemoveRecipient,
  onUpdateRecipient,
  onToggleUpload,
  onImported,
  onNext,
  tokens,
}: RecipientFormProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Batch Payment</CardTitle>
        <CardDescription>Add recipient wallet addresses and amounts</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Token Selection */}
        <div className="space-y-2">
          <label htmlFor="token" className="text-sm font-medium">
            Token
          </label>
          <select
            id="token"
            className={inputClass}
            value={selectedToken}
            onChange={(e) => onTokenChange(e.target.value)}
          >
            {tokens.map((token) => (
              <option key={token.symbol} value={token.symbol}>
                {token.symbol} - {token.name}
              </option>
            ))}
          </select>
        </div>

        {/* Recipients Section */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Recipients</span>
            <div className="flex gap-2">
              <Button onClick={onToggleUpload} size="sm" variant="outline">
                {showUpload ? "Manual entry" : "Import from file"}
              </Button>
              {!showUpload && (
                <Button onClick={onAddRecipient} size="sm" variant="outline">
                  <Plus className="h-4 w-4 mr-1" />
                  Add Recipient
                </Button>
              )}
            </div>
          </div>

          {showUpload ? (
            <UploadRecipients onParsed={onImported} />
          ) : (
            <>
              <div className="space-y-3 max-h-96 overflow-y-auto">
                {recipients.map((r, idx) => (
                  <div key={r.id} className="flex gap-2 items-start p-3 rounded-lg border border-border">
                    <div className="flex-1 space-y-2">
                      <input
                        className={inputClass}
                        placeholder={`Wallet address ${idx + 1}`}
                        value={r.address}
                        onChange={(e) => onUpdateRecipient(r.id, "address", e.target.value)}
                      />
                      <input
                        className={inputClass}
                        type="number"
                        placeholder={`Amount (${selectedToken})`}
                        value={r.amount}
                        onChange={(e) => onUpdateRecipient(r.id, "amount", e.target.value)}
                        min="0"
                        step="0.01"
                      />
                    </div>
                    {recipients.length > 1 && (
                      <Button onClick={() => onRemoveRecipient(r.id)} size="icon" variant="ghost" className="mt-1">
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    )}
                  </div>
                ))}
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
            </>
          )}
        </div>

        <Button onClick={onNext} className="w-full" size="lg">
          Next: Review
          <ArrowRight className="ml-2 h-4 w-4" />
        </Button>
      </CardContent>
    </Card>
  );
}
