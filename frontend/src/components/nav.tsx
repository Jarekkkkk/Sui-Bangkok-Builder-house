import { LucideIcon } from "lucide-react";

import { cn } from "@/lib/utils";
import { buttonVariants } from "./ui/button";
import { Action } from "./Panel";
import { Dispatch, SetStateAction } from "react";

interface NavProps {
  isCollapsed: boolean;
  links: {
    title: string;
    label?: string;
    icon: LucideIcon;
  }[];
  action: Action;
  setAction: Dispatch<SetStateAction<Action>>;
}

export function Nav({ links, isCollapsed, action, setAction }: NavProps) {
  return (
    <div
      data-collapsed={isCollapsed}
      className="group flex flex-col gap-4 py-2 data-[collapsed=true]:py-2"
    >
      <nav className="grid gap-1 px-2 group-[[data-collapsed=true]]:justify-center group-[[data-collapsed=true]]:px-2">
        {links.map((link, index) => (
          <div
            key={index}
            className={cn(
              buttonVariants({
                variant: action == link.title ? "secondary" : "ghost",
                size: "sm",
              }),
              "justify-start",
            )}
            onClick={() => setAction(link.title as Action)}
          >
            <link.icon className="mr-2 h-4 w-4" />
            {link.title}
            {link.label && <span className={cn("ml-auto")}>{link.label}</span>}
          </div>
        ))}
      </nav>
    </div>
  );
}
