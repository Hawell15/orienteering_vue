<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('date')">Data</th>
                <th @click="orderTable('competition_name')">Nume</th>
                <th @click="orderTable('location')">Oraș</th>
                <th @click="orderTable('country')">Țara</th>
                <th @click="orderTable('distance_type')">Tipul Distanței</th>
                <th @click="orderTable('wre_id')">WRE ID</th>
                <th @click="orderTable('ecn')">ECN</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/competitions/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`/competitions/${element.id}`">{{ element.date }}</a></td>
                <td><a :href="`/competitions/${element.id}`">{{ element.competition_name }}</a></td>
                <td>{{ element.location }}</td>
                <td>{{ element.country }}</td>
                <td>{{ element.distance_type }}</td>
                <td>{{ element.wre_id }}</td>
                <td :class="element.ecn ? 'bg-true' : 'bg-false'">
                    {{ element.ecn ? "Da" : "Nu" }}
                </td>
                <td><a class="btn btn-sm btn-warning" :href="`/competitions/${element.id}`">Arată</a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :competition="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast sportiv?')) {
        axios.delete(`/competitions/${id}`).then(() => {
            props.elements = props.elements.filter(competition => competition.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/competitions/${elementData.id}.json`, { competition: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>
