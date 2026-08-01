from django import template

register = template.Library()


@register.filter
def get_item(mapping, key):
    """dict-доступ у шаблонах: section.config|get_item:'button_label'."""
    if isinstance(mapping, dict):
        return mapping.get(key)
    return None
