<template>
    <div class="modal fade" tabindex="-1" id="editModal" aria-labelledby="editModalLabel" aria-hidden="true" ref="modalRef">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editModalLabel">{{ isNew ? 'Creaza Club' : 'Editeaza Clubul'}}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent>
                        <div class="mb-3">
                            <label for="club_name" class="form-label">Nume</label>
                            <input type="text" class="form-control" id="club_name" v-model="localClub.club_name" />
                        </div>
                        <div class="mb-3">
                            <label for="territory" class="form-label">Teritoriu</label>
                            <input type="text" class="form-control" id="territory" v-model="localClub.territory" />
                            <div class="mb-3">
                                <label for="representative" class="form-label">Reprezentant</label>
                                <input type="text" class="form-control" id="representative" v-model="localClub.representative" />
                            </div>
                            <div class="mb-3">
                                <label for="email" class="form-label">Email</label>
                                <input type="text" class="form-control" id="email" v-model="localClub.email" />
                            </div>
                            <div class="mb-3">
                                <label for="phone" class="form-label">Telefon</label>
                                <input type="text" class="form-control" id="phone" v-model="localClub.phone" />
                            </div>
                            <div class="mb-3">
                                <label for="alternative_club_names" class="form-label">Alt Nume</label>
                                <input type="text" class="form-control" id="alternative_club_names" v-model="localClub.alternative_club_names" />
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Inchide</button>
                    <button type="button" class="btn btn-primary" @click="handleSave">Salveaza</button>
                </div>
            </div>
        </div>
    </div>
</template>
<script setup>
import { ref, watch, onMounted } from 'vue'

const props = defineProps({
    club: Object,
    isNew: Boolean
})

const emit = defineEmits(['save'])
const localClub = ref({ ...props.club })
const modalRef = ref(null)
let modalInstance = null

watch(
    () => props.club,
    (newVal) => {
        localClub.value = {
            ...newVal,
            alternative_club_names: Array.isArray(newVal?.alternative_club_names)
                ? newVal.alternative_club_names.join(', ')
                : (newVal?.alternative_club_names || '')
        }
    }
)

onMounted(() => {
    if (Array.isArray(localClub.value.alternative_club_names)) {
        localClub.value.alternative_club_names = localClub.value.alternative_club_names.join(', ')
    } else if (!localClub.value.alternative_club_names) {
        localClub.value.alternative_club_names = ''
    }
})

function show() {
    if (!modalInstance) {
        modalInstance = new bootstrap.Modal(modalRef.value)
    }
    modalInstance.show()
}

function hide() {
    modalInstance.hide()
}

function handleSave() {
    const payload = {
        ...localClub.value,
        alternative_club_names: (localClub.value.alternative_club_names || '')
            .split(',')
            .map(name => name.trim())
            .filter(name => name.length > 0)
    }

    emit('save', payload, hide)
}

defineExpose({ show, hide })
</script>
