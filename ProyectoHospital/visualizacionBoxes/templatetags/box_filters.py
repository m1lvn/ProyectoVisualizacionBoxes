from django import template

register = template.Library()

@register.filter
def lookup(dictionary, key):
    """
    Template filter to access dictionary values by key
    Usage: {{ dict|lookup:key }}
    """
    if hasattr(dictionary, 'get'):
        return dictionary.get(key)
    return None

@register.filter  
def get_item(dictionary, key):
    """
    Alternative filter for dictionary access
    """
    return dictionary.get(key) if dictionary else None
