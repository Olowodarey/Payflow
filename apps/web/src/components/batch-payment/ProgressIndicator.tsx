import { Check } from "lucide-react";

interface ProgressIndicatorProps {
  currentStep: number;
}

export function ProgressIndicator({ currentStep }: ProgressIndicatorProps) {
  const steps = [
    { number: 1, label: "Setup" },
    { number: 2, label: "Review" },
    { number: 3, label: "Complete" },
  ];

  return (
    <div className="mb-8">
      <div className="flex items-center justify-between mb-4">
        {steps.map((s) => (
          <div key={s.number} className="flex flex-col items-center flex-1">
            <div className="flex items-center w-full">
              {s.number > 1 && (
                <div
                  className={`h-1 flex-1 rounded transition-colors ${
                    s.number <= currentStep ? "bg-success" : "bg-muted"
                  }`}
                />
              )}
              <div
                className={`h-8 w-8 rounded-full flex items-center justify-center text-sm font-semibold transition-colors ${
                  s.number < currentStep
                    ? "bg-success text-success-foreground"
                    : s.number === currentStep
                    ? "bg-primary text-primary-foreground"
                    : "bg-muted text-muted-foreground"
                } ${s.number === 1 ? "ml-0" : "mx-2"} ${s.number === 3 ? "mr-0" : ""}`}
              >
                {s.number < currentStep ? <Check className="h-4 w-4" /> : s.number}
              </div>
              {s.number < 3 && (
                <div
                  className={`h-1 flex-1 rounded transition-colors ${
                    s.number < currentStep ? "bg-success" : "bg-muted"
                  }`}
                />
              )}
            </div>
            <span className="text-xs sm:text-sm text-muted-foreground mt-2">{s.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
