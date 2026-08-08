# Propshaft memoizes Rails.application.assets very early during boot (in its
# own "propshaft.assets_middleware" initializer), before every engine has
# necessarily finished registering its own asset paths. Once memoized, it's
# never rebuilt, so paths appended afterwards (by us or by other engines)
# are silently ignored by the actual resolver, even though
# config.assets.paths itself keeps growing correctly.
#
# Forcing a fresh Assembly here, inside config.after_initialize, guarantees
# it's built using the FINAL, complete state of config.assets.paths, since
# after_initialize callbacks run strictly after all other initializers.
Rails.application.config.after_initialize do
  Rails.application.assets = Propshaft::Assembly.new(Rails.application.config.assets)
end
