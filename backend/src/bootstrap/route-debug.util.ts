import { INestApplication } from '@nestjs/common';

type ExpressLayer = {
  route?: { path: string; methods: Record<string, boolean> };
  name?: string;
  handle?: { stack?: ExpressLayer[]; _router?: { stack?: ExpressLayer[] } };
  regexp?: RegExp;
};

function collectExpressRoutes(stack: ExpressLayer[], prefix = ''): string[] {
  const routes: string[] = [];

  for (const layer of stack) {
    if (layer.route) {
      const methods = Object.keys(layer.route.methods)
        .filter((method) => layer.route!.methods[method])
        .map((method) => method.toUpperCase())
        .join(',');
      routes.push(`${methods} ${prefix}${layer.route.path}`);
      continue;
    }

    const nestedStack =
      layer.handle?.stack ??
      layer.handle?._router?.stack ??
      (layer.name === 'router' ? layer.handle?.stack : undefined);

    if (nestedStack) {
      routes.push(...collectExpressRoutes(nestedStack, prefix));
    }
  }

  return routes;
}

function resolveExpressStack(expressApp: Record<string, unknown>): ExpressLayer[] | undefined {
  const router = expressApp._router as { stack?: ExpressLayer[] } | undefined;
  if (router?.stack?.length) return router.stack;

  const lazyRouter = expressApp.router as { stack?: ExpressLayer[] } | undefined;
  if (lazyRouter?.stack?.length) return lazyRouter.stack;

  const stack: ExpressLayer[] = [];
  for (const value of Object.values(expressApp)) {
    if (
      value &&
      typeof value === 'object' &&
      'stack' in value &&
      Array.isArray((value as { stack?: unknown }).stack)
    ) {
      stack.push(...((value as { stack: ExpressLayer[] }).stack ?? []));
    }
  }

  return stack.length ? stack : undefined;
}

export function logRuntimeRouteRegistration(app: INestApplication): void {
  const adapter = app.getHttpAdapter();
  console.log(`ROUTE DEBUG: HTTP adapter = ${adapter.constructor.name}`);

  if (adapter.constructor.name !== 'ExpressAdapter') {
    console.log('ROUTE DEBUG: Express route stack dump skipped (not Express)');
    return;
  }

  const expressApp = adapter.getInstance() as Record<string, unknown>;
  const stack = resolveExpressStack(expressApp);
  if (!stack) {
    console.log(
      'ROUTE DEBUG: Express router stack unavailable on adapter instance',
    );
    return;
  }

  const routes = collectExpressRoutes(stack);
  const healthRoutes = routes.filter((route) =>
    /live|ready|health/i.test(route),
  );

  console.log(`ROUTE DEBUG: Express route count = ${routes.length}`);
  console.log('ROUTE DEBUG: Health-related Express routes:', healthRoutes);
  console.log('ROUTE DEBUG: Express routes sample:', routes.slice(0, 20));
}
